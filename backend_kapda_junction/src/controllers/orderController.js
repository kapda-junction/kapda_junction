const crypto = require('crypto');
const Order = require('../models/Order');
const ReturnRequest = require('../models/ReturnRequest');
const Product = require('../models/Product');
const Coupon = require('../models/Coupon');
const Razorpay = require('razorpay');
const storePolicy = require('../services/storePolicyService');
const { buildPublicTrackingUrl } = require('../utils/trackingUrl');
const {
  buildCartLinesFromRequestItems,
  validateAndApply,
  orderItemsForDb
} = require('../services/couponService');
const { notifyOrderPush, notifyReturnsPush } = require('../services/customerPushService');

/** Safely extracts the first product image URL from a populated order. */
function firstProductImage(order) {
  return order?.items?.[0]?.product?.images?.[0] || undefined;
}

const rzp = process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET
  ? new Razorpay({ key_id: process.env.RAZORPAY_KEY_ID, key_secret: process.env.RAZORPAY_KEY_SECRET })
  : null;

const CANCEL_REQUEST_REASON_MIN = 10;

function orderToClient(doc) {
  const o = doc.toObject ? doc.toObject() : { ...doc };
  o.trackingUrl = buildPublicTrackingUrl(
    o.shippingCarrier,
    o.shippingAwb,
    o.shippingTrackingUrlOverride
  );
  return o;
}

/** Validate stock for order items. Returns { ok: boolean, message?: string } */
async function validateStock(items) {
  for (const it of items) {
    const productId = it.product?._id || it.product;
    const prod = await Product.findById(productId).select('variants soldOut');
    if (!prod || prod.soldOut) return { ok: false, message: `${it.name || 'Product'} is out of stock` };
    const qty = Math.max(1, parseInt(it.quantity) || 1);
    if (prod.variants?.length) {
      const v = prod.variants.find(
        (x) => (it.color ? x.color === it.color : true) && (it.size ? x.size === it.size : true)
      );
      if (!v) return { ok: false, message: `${it.name || 'Product'}: variant not found` };
      if ((v.stock || 0) < qty) return { ok: false, message: `${it.name || 'Product'} (${it.color || ''} ${it.size || ''}) - only ${v.stock || 0} left` };
    } else {
      const total = prod.variants?.reduce((s, x) => s + (x.stock || 0), 0) ?? 0;
      if (total < qty) return { ok: false, message: `${it.name || 'Product'} - only ${total} left` };
    }
  }
  return { ok: true };
}

/** Reduce stock for order items when payment is captured */
async function reduceStock(items) {
  for (const it of items) {
    const productId = it.product?._id || it.product;
    const prod = await Product.findById(productId);
    if (!prod || !prod.variants?.length) continue;
    const qty = Math.max(1, parseInt(it.quantity) || 1);
    const v = prod.variants.find(
      (x) => (it.color ? x.color === it.color : true) && (it.size ? x.size === it.size : true)
    );
    if (v && (v.stock || 0) >= qty) {
      v.stock = Math.max(0, (v.stock || 0) - qty);
      await prod.save();
    }
  }
}

/** Restore stock when order is refunded */
async function restoreStock(items) {
  for (const it of items) {
    const productId = it.product?._id || it.product;
    const prod = await Product.findById(productId);
    if (!prod || !prod.variants?.length) continue;
    const qty = Math.max(1, parseInt(it.quantity) || 1);
    const v = prod.variants.find(
      (x) => (it.color ? x.color === it.color : true) && (it.size ? x.size === it.size : true)
    );
    if (v) {
      v.stock = (v.stock || 0) + qty;
      await prod.save();
    }
  }
}

/**
 * Confirm DB order after Razorpay payment is captured. Idempotent for duplicate webhook / verify calls.
 * @param {string} mongoOrderId
 * @param {{ id: string, order_id: string, amount: number|string, status: string }} payment
 * @param {{ signature?: string }} opts
 */
async function finalizeCapturedPayment(mongoOrderId, payment, opts = {}) {
  if (!payment?.id || !payment?.order_id) {
    return { ok: false, statusCode: 400, error: 'Invalid payment' };
  }
  if (payment.status !== 'captured') {
    return { ok: false, statusCode: 400, error: 'Payment not captured' };
  }
  const expectedAmount = Math.round(Number(payment.amount));
  if (!Number.isFinite(expectedAmount)) {
    return { ok: false, statusCode: 400, error: 'Invalid payment amount' };
  }

  const orderBefore = await Order.findById(mongoOrderId).populate('items.product');
  if (!orderBefore) {
    return { ok: false, statusCode: 404, error: 'Order not found' };
  }

  if (orderBefore.razorpayOrderId !== payment.order_id) {
    return { ok: false, statusCode: 400, error: 'Razorpay order mismatch' };
  }

  const orderPaise = Math.round((orderBefore.totalAmount || 0) * 100);
  if (expectedAmount !== orderPaise) {
    return { ok: false, statusCode: 400, error: 'Amount mismatch' };
  }

  if (orderBefore.paymentStatus === 'paid' && orderBefore.razorpayPaymentId === payment.id) {
    const populated = await Order.findById(mongoOrderId)
      .populate('user', 'name email')
      .populate('items.product', 'name price images');
    return { ok: true, idempotent: true, order: populated };
  }

  if (orderBefore.paymentStatus === 'paid' && orderBefore.razorpayPaymentId !== payment.id) {
    return { ok: false, statusCode: 409, error: 'Order already paid with a different payment' };
  }

  if (orderBefore.paymentStatus !== 'pending') {
    return { ok: false, statusCode: 400, error: 'Order cannot be confirmed' };
  }

  const update = {
    paymentStatus: 'paid',
    status: 'confirmed',
    razorpayPaymentId: payment.id
  };
  if (opts.signature) {
    update.razorpaySignature = opts.signature;
  }

  const updated = await Order.findOneAndUpdate(
    { _id: mongoOrderId, paymentStatus: 'pending', razorpayOrderId: payment.order_id },
    { $set: update },
    { new: true }
  ).populate('items.product');

  if (!updated) {
    const again = await Order.findById(mongoOrderId);
    if (again && again.paymentStatus === 'paid' && again.razorpayPaymentId === payment.id) {
      const populated = await Order.findById(mongoOrderId)
        .populate('user', 'name email')
        .populate('items.product', 'name price images');
      return { ok: true, idempotent: true, order: populated };
    }
    return { ok: false, statusCode: 409, error: 'Could not confirm order — try again' };
  }

  const captureJustConfirmed = true;

  const stockOk = await validateStock(updated.items);
  if (!stockOk.ok && rzp) {
    try {
      const amountPaise = Math.round((updated.totalAmount || 0) * 100);
      const refundResult = await rzp.payments.refund(payment.id, { amount: amountPaise });
      const refundPaise = refundResult.amount != null ? Number(refundResult.amount) : amountPaise;
      updated.paymentStatus = 'refunded';
      updated.status = 'cancelled';
      updated.refundStatus = 'pending';
      updated.razorpayRefundId = refundResult.id;
      updated.refundAmount = refundPaise / 100;
      updated.cancelReason = stockOk.message || 'Insufficient stock - auto refund';
      updated.cancelledAt = new Date();
      await updated.save();
    } catch (refundErr) {
      updated.cancelReason = stockOk.message || 'Insufficient stock - refund pending';
      updated.refundStatus = 'failed';
      updated.refundLastError = (refundErr.error && refundErr.error.description) || refundErr.message || 'Auto-refund failed';
      await updated.save();
    }
  } else if (stockOk.ok) {
    await reduceStock(updated.items);
    await Order.updateOne({ _id: mongoOrderId }, { $set: { stockDeducted: true } });
    if (updated.coupon) {
      await Coupon.findByIdAndUpdate(updated.coupon, { $inc: { usedCount: 1 } });
    }
  }

  const populated = await Order.findById(mongoOrderId)
    .populate('user', 'name email')
    .populate('items.product', 'name price images');

  if (captureJustConfirmed) {
    const userId = populated.user?._id || populated.user;
    if (userId) {
      const oid = populated._id;
      const img = firstProductImage(populated);
      if (populated.paymentStatus === 'paid' && populated.status === 'confirmed') {
        notifyOrderPush(userId, oid, 'Order confirmed', 'Payment received — we\'re preparing your order.', img)
          .catch(() => {});
      } else if (populated.paymentStatus === 'refunded') {
        const stockIssue = (populated.cancelReason || '').toLowerCase().includes('stock');
        notifyOrderPush(
          userId,
          oid,
          'Refund processing',
          stockIssue
            ? 'We couldn\'t fulfil your order. Your refund is on the way.'
            : 'Your payment has been refunded.',
          img
        ).catch(() => {});
      }
    }
  }

  return { ok: true, order: populated };
}

exports.getAll = async (req, res, next) => {
  try {
    const filter = req.user.role === 'admin' ? {} : { user: req.user.id };
    const orders = await Order.find(filter).populate('user', 'name email').populate('items.product', 'name price images').sort('-createdAt');
    res.json(orders.map(orderToClient));
  } catch (err) {
    next(err);
  }
};

exports.getOne = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id).populate('user', 'name email').populate('items.product', 'name price images');
    if (!order) return res.status(404).json({ message: 'Order not found' });
    if (req.user.role !== 'admin' && order.user._id.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    res.json(orderToClient(order));
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const order = await Order.create({ ...req.body, user: req.user.id });
    res.status(201).json(order);
  } catch (err) {
    next(err);
  }
};

exports.updateStatus = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: 'Order not found' });
    const prevStatus = order.status;
    const {
      status,
      shippingAwb,
      shippingCarrier,
      shippingTrackingUrlOverride,
      refundNote
    } = req.body || {};
    if (status != null) order.status = status;
    if (shippingAwb !== undefined) order.shippingAwb = String(shippingAwb).trim();
    if (shippingCarrier !== undefined) {
      order.shippingCarrier = String(shippingCarrier).trim() || 'India Post';
    }
    if (shippingTrackingUrlOverride !== undefined) {
      order.shippingTrackingUrlOverride = String(shippingTrackingUrlOverride).trim();
    }
    if (refundNote !== undefined && req.user.role === 'admin') {
      order.refundNote = String(refundNote).trim().slice(0, 500);
    }
    if (status === 'shipped' && !order.shippedAt) order.shippedAt = new Date();
    await order.save();
    const populated = await Order.findById(order._id)
      .populate('user', 'name email')
      .populate('items.product', 'name price images');

    const uid = order.user;
    if (uid && status != null && order.status !== prevStatus) {
      const oid = order._id;
      const img = firstProductImage(populated);
      if (order.status === 'confirmed') {
        notifyOrderPush(uid, oid, 'Order confirmed', 'Your order is confirmed — we\'ll ship it soon.', img)
          .catch(() => {});
      } else if (order.status === 'shipped') {
        const awb = (order.shippingAwb || '').trim();
        const body = awb.length
          ? `On the way — tracking: ${awb}. Tap to open your order.`
          : 'Your order has shipped. Tap to track in the app.';
        notifyOrderPush(uid, oid, 'Shipped', body, img).catch(() => {});
      } else if (order.status === 'delivered') {
        notifyOrderPush(uid, oid, 'Delivered', 'Your order was delivered. We hope you love it!', img)
          .catch(() => {});
      } else if (order.status === 'cancelled') {
        notifyOrderPush(
          uid,
          oid,
          'Order cancelled',
          (order.cancelReason || 'Your order was cancelled.').slice(0, 200),
          img
        ).catch(() => {});
      }
    }

    res.json(orderToClient(populated));
  } catch (err) {
    next(err);
  }
};

/** Admin: retry Razorpay refund when previous attempt failed */
exports.retryRefund = async (req, res, next) => {
  try {
    if (!rzp) return res.status(503).json({ message: 'Payment service not configured' });
    const order = await Order.findById(req.params.id).populate('items.product', 'images');
    if (!order) return res.status(404).json({ message: 'Order not found' });
    if (order.paymentStatus !== 'paid' || !order.razorpayPaymentId) {
      return res.status(400).json({ message: 'Order is not in a refundable paid state' });
    }
    if (order.refundStatus !== 'failed') {
      return res.status(400).json({ message: 'Retry is only for failed refunds' });
    }
    const amountPaise = Math.round((order.totalAmount || 0) * 100);
    const refund = await rzp.payments.refund(order.razorpayPaymentId, { amount: amountPaise });
    order.refundStatus = 'pending';
    order.razorpayRefundId = refund.id;
    order.refundAmount = order.totalAmount;
    order.refundLastError = '';
    await order.save();
    notifyOrderPush(
      order.user,
      order._id,
      'Refund retry',
      'We\'ve re-initiated your refund. It may take a few days to show in your account.',
      firstProductImage(order)
    ).catch(() => {});
    res.json({
      message: 'Refund re-initiated',
      order: orderToClient(order)
    });
  } catch (err) {
    try {
      const order = await Order.findById(req.params.id);
      if (order) {
        order.refundLastError = (err.error && err.error.description) || err.message || 'Refund error';
        order.refundStatus = 'failed';
        await order.save();
      }
    } catch (_) {}
    if (err.error?.description) return res.status(400).json({ message: err.error.description });
    next(err);
  }
};

/** Creates order in DB and Razorpay, returns payload for frontend checkout */
exports.createPayment = async (req, res, next) => {
  try {
    if (!rzp) return res.status(503).json({ message: 'Payment service not configured' });
    const { items, shippingAddress, couponCode } = req.body;
    if (!items?.length || !shippingAddress) {
      return res.status(400).json({ message: 'items and shippingAddress required' });
    }
    const built = await buildCartLinesFromRequestItems(items);
    if (built.error) return res.status(400).json({ message: built.error });

    const applied = await validateAndApply(req.user.id, built.lines, built.subtotal, couponCode);
    if (applied.error) return res.status(400).json({ message: applied.error });

    const orderItems = orderItemsForDb(built.lines);
    const stockOk = await validateStock(orderItems);
    if (!stockOk.ok) return res.status(400).json({ message: stockOk.message });

    const totalAmount = applied.total;
    const order = await Order.create({
      user: req.user.id,
      items: orderItems,
      subtotal: built.subtotal,
      discountAmount: applied.discountAmount || 0,
      coupon: applied.coupon?._id || null,
      couponCode: applied.coupon ? applied.coupon.code : '',
      totalAmount,
      shippingAddress,
      paymentMethod: 'razorpay',
      paymentStatus: 'pending',
      status: 'pending'
    });
    const amountPaise = Math.round(totalAmount * 100);
    try {
      const rzpOrder = await rzp.orders.create({
        amount: amountPaise,
        currency: 'INR',
        receipt: order._id.toString()
      });
      order.razorpayOrderId = rzpOrder.id;
      await order.save();
      res.status(201).json({
        orderId: order._id,
        razorpayOrderId: rzpOrder.id,
        amount: amountPaise,
        currency: 'INR',
        key: process.env.RAZORPAY_KEY_ID
      });
    } catch (gwErr) {
      order.status = 'cancelled';
      order.paymentStatus = 'failed';
      order.cancelReason = 'Could not initialize payment with gateway';
      await order.save();
      if (gwErr.error?.description) return res.status(503).json({ message: gwErr.error.description });
      return res.status(503).json({ message: 'Payment gateway error' });
    }
  } catch (err) {
    next(err);
  }
};

/** App calls after Razorpay checkout success — verifies signature + payment with Razorpay, then confirms order (idempotent). */
exports.verifyPayment = async (req, res, next) => {
  try {
    if (!rzp) return res.status(503).json({ message: 'Payment service not configured' });
    const { orderId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body || {};
    if (!orderId || !razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return res.status(400).json({
        message: 'orderId, razorpayOrderId, razorpayPaymentId, razorpaySignature required'
      });
    }
    const secret = process.env.RAZORPAY_KEY_SECRET;
    if (!secret) return res.status(503).json({ message: 'Payment service not configured' });
    const expectedSig = crypto.createHmac('sha256', secret)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest('hex');
    if (expectedSig !== razorpaySignature) {
      return res.status(400).json({ message: 'Invalid payment signature' });
    }

    const order = await Order.findById(orderId);
    if (!order) return res.status(404).json({ message: 'Order not found' });
    if (order.user.toString() !== req.user.id.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    let payment;
    try {
      payment = await rzp.payments.fetch(razorpayPaymentId);
    } catch (e) {
      return res.status(400).json({ message: (e.error && e.error.description) || 'Could not verify payment' });
    }

    const result = await finalizeCapturedPayment(order._id.toString(), payment, {
      signature: razorpaySignature
    });
    if (!result.ok) {
      return res.status(result.statusCode || 400).json({ message: result.error || 'Verification failed' });
    }
    res.json({ message: 'Payment verified', order: orderToClient(result.order) });
  } catch (err) {
    next(err);
  }
};

/** Razorpay webhook - req.body is raw Buffer (use express.raw) */
exports.webhook = async (req, res) => {
  try {
    const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
    console.log(`[webhook] hit | secret set: ${!!secret} | sig header: ${!!req.headers['x-razorpay-signature']}`);
    if (!secret) { console.log('[webhook] no secret — skipping'); return res.status(200).send('OK'); }
    const signature = req.headers['x-razorpay-signature'];
    if (!signature) { console.log('[webhook] no signature header'); return res.status(400).send('Bad Request'); }
    const body = req.body;
    const raw = Buffer.isBuffer(body) ? body : JSON.stringify(body);
    const expected = crypto.createHmac('sha256', secret).update(raw).digest('hex');
    if (expected !== signature) { console.log(`[webhook] sig mismatch | expected=${expected.slice(0,10)}... got=${signature.slice(0,10)}...`); return res.status(400).send('Invalid signature'); }
    const payload = JSON.parse(Buffer.isBuffer(body) ? body.toString() : JSON.stringify(body));
    const event = payload.event;
    console.log(`[webhook] event="${event}"`);

    // payment.captured — same path as app verify-payment (atomic + idempotent)
    if (event === 'payment.captured') {
      const payment = payload.payload?.payment?.entity;
      const rzOrderId = payment?.order_id;
      const ourOrder = await Order.findOne({ razorpayOrderId: rzOrderId });
      if (ourOrder) {
        const result = await finalizeCapturedPayment(ourOrder._id.toString(), payment, {});
        if (result.ok) {
          console.log(`[webhook] order ${ourOrder._id} capture ok idempotent=${!!result.idempotent}`);
        } else {
          console.warn(`[webhook] order ${ourOrder._id} capture skipped: ${result.error}`);
        }
      }
    }

    // payment.failed - user abandoned or payment failed
    if (event === 'payment.failed') {
      const payment = payload.payload?.payment?.entity;
      const orderId = payment?.order_id;
      const ourOrder = await Order.findOne({ razorpayOrderId: orderId });
      if (ourOrder && ourOrder.paymentStatus === 'pending') {
        ourOrder.paymentStatus = 'failed';
        ourOrder.status = 'cancelled';
        ourOrder.cancelReason = 'Payment failed';
        ourOrder.cancelledAt = new Date();
        await ourOrder.save();
        console.log(`[webhook] order ${ourOrder._id} → cancelled (payment failed)`);
        notifyOrderPush(
          ourOrder.user,
          ourOrder._id,
          'Payment unsuccessful',
          'Your payment didn\'t go through. You can try again from your cart.'
        ).catch(() => {});
      }
    }

    // refund.processed — idempotent (duplicate webhooks must not double-restore stock)
    if (event === 'refund.processed') {
      const refund = payload.payload?.refund?.entity;
      const paymentId = refund?.payment_id;
      const patch = {
        paymentStatus: 'refunded',
        status: 'cancelled',
        refundStatus: 'processed',
        razorpayRefundId: refund?.id,
        refundAmount: (refund?.amount || 0) / 100
      };
      const updated = await Order.findOneAndUpdate(
        { razorpayPaymentId: paymentId, refundStatus: { $ne: 'processed' } },
        { $set: patch },
        { new: true }
      ).populate('items.product');
      if (updated) {
        if (!updated.cancelledAt) {
          updated.cancelledAt = new Date();
          await updated.save();
        }
        // false = capture never reduced stock (e.g. auto-refund). undefined = legacy doc → keep old “always restore” behaviour.
        if (updated.stockDeducted !== false) {
          await restoreStock(updated.items);
          await Order.updateOne({ _id: updated._id }, { $set: { stockDeducted: false } });
        }
        notifyOrderPush(
          updated.user,
          updated._id,
          'Refund completed',
          'Your refund has been processed. It can take 5–7 days to reach your bank or UPI.',
          firstProductImage(updated)
        ).catch(() => {});
      }
    }

    // refund.failed - log for admin
    if (event === 'refund.failed') {
      const refund = payload.payload?.refund?.entity;
      const paymentId = refund?.payment_id;
      const ourOrder = await Order.findOne({ razorpayPaymentId: paymentId });
      if (ourOrder) {
        ourOrder.refundStatus = 'failed';
        ourOrder.refundLastError = (refund && (refund.status || refund.error_description)) || 'refund.failed webhook';
        await ourOrder.save();
        notifyOrderPush(
          ourOrder.user,
          ourOrder._id,
          'Refund issue',
          'There was a problem completing your refund. Please contact support with your order ID.'
        ).catch(() => {});
      }
      console.error('Razorpay refund failed:', JSON.stringify(refund));
    }

    res.status(200).send('OK');
  } catch (err) {
    console.error('Webhook error:', err);
    res.status(500).send('Error');
  }
};

/** Customer: cancel before shipment. Same refund rules as admin for paid orders. */
exports.cancelOrderCustomer = async (req, res, next) => {
  try {
    if (!(await storePolicy.isCustomerOrderCancelEnabled())) {
      return res.status(403).json({
        message: 'Cancelling orders from the app is disabled. Please contact support or WhatsApp us.'
      });
    }
    const order = await Order.findById(req.params.id).populate('items.product', 'images');
    if (!order) return res.status(404).json({ message: 'Order not found' });
    if (order.user.toString() !== req.user.id.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    if (order.status === 'cancelled') return res.status(400).json({ message: 'Order already cancelled' });
    if (!['pending', 'confirmed'].includes(order.status)) {
      return res.status(400).json({
        message: 'This order can no longer be cancelled online. For delivered orders, use return or exchange.'
      });
    }
    const { reason } = req.body || {};

    if (order.paymentStatus === 'pending' && order.razorpayOrderId && rzp) {
      try {
        const collection = await rzp.orders.fetchPayments(order.razorpayOrderId);
        const items = collection.items || [];
        const captured = items.find((p) => p.status === 'captured');
        if (captured) {
          return res.status(409).json({
            message:
              'Payment may have completed. Refresh your orders list or wait a moment, then try again.'
          });
        }
      } catch (_) { /* ignore gateway errors; proceed with cancel */ }
    }

    if (order.paymentStatus === 'paid' && order.razorpayPaymentId) {
      const detail = String(reason || '').trim();
      if (detail.length < CANCEL_REQUEST_REASON_MIN) {
        return res.status(400).json({
          message: `Please explain why you want to cancel (at least ${CANCEL_REQUEST_REASON_MIN} characters). Admin will review your request and proof before any refund.`
        });
      }
      const videoRequired = await storePolicy.isReturnVideoRequired();
      const v = String(req.body.videoUrl || '').trim();
      if (videoRequired && !v.startsWith('http')) {
        return res.status(400).json({
          message: 'A short proof video is required — record and upload from the app, then submit your cancellation request.'
        });
      }
      const terminal = ReturnRequest.TERMINAL_RETURN_STATUSES;
      const activeOther = await ReturnRequest.findOne({
        order: order._id,
        user: req.user.id,
        status: { $nin: terminal }
      });
      if (activeOther) {
        return res.status(400).json({
          message: 'You already have an open return, exchange, or cancellation request for this order.'
        });
      }
      const rr = await ReturnRequest.create({
        user: req.user.id,
        order: order._id,
        type: 'order_cancel',
        items: [],
        reason: 'Order cancellation (before shipment)',
        reasonDetail: detail,
        videoUrl: videoRequired ? v : (v || ''),
        exchangeFor: { size: '', color: '' },
        status: 'requested'
      });
      const populated = await ReturnRequest.findById(rr._id)
        .populate('order', 'status totalAmount paymentStatus')
        .populate('user', 'name email');
      notifyReturnsPush(
        req.user.id,
        'Cancellation request sent',
        'We will verify your details and process a refund only after approval.',
        firstProductImage(order)
      ).catch(() => {});
      return res.status(201).json({
        message:
          'Cancellation request submitted. An admin will verify your proof (including video) before starting any refund.',
        cancelRequest: populated,
        order: orderToClient(order)
      });
    }

    order.status = 'cancelled';
    order.paymentStatus = order.paymentStatus === 'pending' ? 'failed' : order.paymentStatus;
    order.cancelReason = reason || 'Cancelled by customer';
    order.cancelledBy = req.user.id;
    order.cancelledAt = new Date();
    await order.save();
    notifyOrderPush(
      order.user,
      order._id,
      'Order cancelled',
      (order.cancelReason || 'Your order was cancelled.').slice(0, 200),
      firstProductImage(order)
    ).catch(() => {});
    res.json(orderToClient(order));
  } catch (err) {
    if (err.error?.description) return res.status(400).json({ message: err.error.description });
    next(err);
  }
};

/** Admin: Cancel order. If paid, initiates refund via Razorpay. */
exports.cancelOrder = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id).populate('items.product', 'images');
    if (!order) return res.status(404).json({ message: 'Order not found' });
    if (order.status === 'cancelled') return res.status(400).json({ message: 'Order already cancelled' });
    const { reason } = req.body || {};
    const img = firstProductImage(order);

    if (order.paymentStatus === 'paid' && order.razorpayPaymentId) {
      if (!rzp) return res.status(503).json({ message: 'Payment service not configured' });
      const amountPaise = Math.round((order.totalAmount || 0) * 100);
      try {
        const refund = await rzp.payments.refund(order.razorpayPaymentId, { amount: amountPaise });
        order.refundStatus = 'pending';
        order.razorpayRefundId = refund.id;
        order.refundAmount = order.totalAmount;
        order.refundLastError = '';
        order.cancelReason = reason || 'Cancelled by admin';
        order.cancelledBy = req.user.id;
        order.cancelledAt = new Date();
        order.status = 'cancelled';
        await order.save();
        notifyOrderPush(
          order.user,
          order._id,
          'Refund started',
          'Your order was cancelled and a refund has been started. Allow 5–7 working days.',
          img
        ).catch(() => {});
        return res.json({
          message: 'Refund initiated. Customer will receive amount in 5-7 days.',
          order: orderToClient(order)
        });
      } catch (refErr) {
        order.refundStatus = 'failed';
        order.refundLastError = (refErr.error && refErr.error.description) || refErr.message || 'Refund failed';
        order.cancelReason = reason || 'Cancelled by admin — refund failed';
        order.cancelledBy = req.user.id;
        order.cancelledAt = new Date();
        order.status = 'cancelled';
        await order.save();
        notifyOrderPush(
          order.user,
          order._id,
          'Refund issue',
          'Your order was cancelled but the refund needs manual help. Please contact support.',
          img
        ).catch(() => {});
        return res.status(400).json({
          message: order.refundLastError,
          order: orderToClient(order)
        });
      }
    }

    order.status = 'cancelled';
    order.paymentStatus = order.paymentStatus === 'pending' ? 'failed' : order.paymentStatus;
    order.cancelReason = reason || 'Cancelled by admin';
    order.cancelledBy = req.user.id;
    order.cancelledAt = new Date();
    await order.save();
    notifyOrderPush(
      order.user,
      order._id,
      'Order cancelled',
      (order.cancelReason || 'Your order was cancelled by the store.').slice(0, 200),
      img
    ).catch(() => {});
    res.json(orderToClient(order));
  } catch (err) {
    if (err.error?.description) return res.status(400).json({ message: err.error.description });
    next(err);
  }
};
