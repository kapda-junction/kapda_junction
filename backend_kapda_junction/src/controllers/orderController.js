const crypto = require('crypto');
const Order = require('../models/Order');
const Product = require('../models/Product');
const Razorpay = require('razorpay');

const rzp = process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET
  ? new Razorpay({ key_id: process.env.RAZORPAY_KEY_ID, key_secret: process.env.RAZORPAY_KEY_SECRET })
  : null;

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

exports.getAll = async (req, res, next) => {
  try {
    const filter = req.user.role === 'admin' ? {} : { user: req.user.id };
    const orders = await Order.find(filter).populate('user', 'name email').populate('items.product', 'name price images').sort('-createdAt');
    res.json(orders);
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
    res.json(order);
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
    const order = await Order.findByIdAndUpdate(req.params.id, { status: req.body.status }, { new: true });
    if (!order) return res.status(404).json({ message: 'Order not found' });
    res.json(order);
  } catch (err) {
    next(err);
  }
};

/** Creates order in DB and Razorpay, returns payload for frontend checkout */
exports.createPayment = async (req, res, next) => {
  try {
    if (!rzp) return res.status(503).json({ message: 'Payment service not configured' });
    const { items, totalAmount, shippingAddress } = req.body;
    if (!items?.length || !totalAmount || !shippingAddress) {
      return res.status(400).json({ message: 'items, totalAmount and shippingAddress required' });
    }
    const stockOk = await validateStock(items);
    if (!stockOk.ok) return res.status(400).json({ message: stockOk.message });
    const order = await Order.create({
      user: req.user.id,
      items,
      totalAmount,
      shippingAddress,
      paymentMethod: 'razorpay',
      paymentStatus: 'pending',
      status: 'pending'
    });
    const amountPaise = Math.round(totalAmount * 100);
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

    // payment.captured - payment success; also check stock (race condition) → auto-refund if insufficient
    if (event === 'payment.captured') {
      const payment = payload.payload?.payment?.entity;
      const orderId = payment?.order_id;
      const ourOrder = await Order.findOne({ razorpayOrderId: orderId }).populate('items.product');
      if (ourOrder && ourOrder.paymentStatus !== 'paid') {
        ourOrder.paymentStatus = 'paid';
        ourOrder.status = 'confirmed';
        ourOrder.razorpayPaymentId = payment.id;
        await ourOrder.save();
        console.log(`[webhook] order ${ourOrder._id} → confirmed`);

        // Post-payment stock check: if stock insufficient, auto-refund
        const stockOk = await validateStock(ourOrder.items);
        if (!stockOk.ok && rzp) {
          try {
            const amountPaise = Math.round((ourOrder.totalAmount || 0) * 100);
            await rzp.payments.refund(payment.id, { amount: amountPaise });
            ourOrder.paymentStatus = 'refunded';
            ourOrder.status = 'cancelled';
            ourOrder.refundStatus = 'pending';
            ourOrder.cancelReason = stockOk.message || 'Insufficient stock - auto refund';
            ourOrder.cancelledAt = new Date();
            await ourOrder.save();
            console.log('Auto-refund for insufficient stock:', ourOrder._id, stockOk.message);
          } catch (refundErr) {
            ourOrder.cancelReason = stockOk.message || 'Insufficient stock - refund pending';
            ourOrder.refundStatus = 'failed';
            await ourOrder.save();
            console.error('Auto-refund failed:', refundErr);
          }
        } else if (stockOk.ok) {
          // Stock OK – reduce inventory for sold items
          await reduceStock(ourOrder.items);
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
      }
    }

    // refund.processed - refund complete
    if (event === 'refund.processed') {
      const refund = payload.payload?.refund?.entity;
      const paymentId = refund?.payment_id;
      const ourOrder = await Order.findOne({ razorpayPaymentId: paymentId });
      if (ourOrder) {
        ourOrder.paymentStatus = 'refunded';
        ourOrder.status = 'cancelled';
        ourOrder.refundStatus = 'processed';
        ourOrder.razorpayRefundId = refund?.id;
        ourOrder.refundAmount = (refund?.amount || 0) / 100;
        if (!ourOrder.cancelledAt) ourOrder.cancelledAt = new Date();
        await ourOrder.save();
        // Restore inventory when refund completes
        await restoreStock(ourOrder.items);
      }
    }

    // refund.failed - log for admin
    if (event === 'refund.failed') {
      const refund = payload.payload?.refund?.entity;
      const paymentId = refund?.payment_id;
      const ourOrder = await Order.findOne({ razorpayPaymentId: paymentId });
      if (ourOrder) {
        ourOrder.refundStatus = 'failed';
        await ourOrder.save();
      }
      console.error('Razorpay refund failed:', JSON.stringify(refund));
    }

    res.status(200).send('OK');
  } catch (err) {
    console.error('Webhook error:', err);
    res.status(500).send('Error');
  }
};

/** Admin: Cancel order. If paid, initiates refund via Razorpay. */
exports.cancelOrder = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: 'Order not found' });
    if (order.status === 'cancelled') return res.status(400).json({ message: 'Order already cancelled' });
    const { reason } = req.body || {};

    if (order.paymentStatus === 'paid' && order.razorpayPaymentId) {
      if (!rzp) return res.status(503).json({ message: 'Payment service not configured' });
      const amountPaise = Math.round((order.totalAmount || 0) * 100);
      const refund = await rzp.payments.refund(order.razorpayPaymentId, { amount: amountPaise });
      order.refundStatus = 'pending';
      order.razorpayRefundId = refund.id;
      order.refundAmount = order.totalAmount;
      order.cancelReason = reason || 'Cancelled by admin';
      order.cancelledBy = req.user.id;
      order.cancelledAt = new Date();
      order.status = 'cancelled';
      await order.save();
      return res.json({ message: 'Refund initiated. Customer will receive amount in 5-7 days.', order });
    }

    order.status = 'cancelled';
    order.paymentStatus = order.paymentStatus === 'pending' ? 'failed' : order.paymentStatus;
    order.cancelReason = reason || 'Cancelled by admin';
    order.cancelledBy = req.user.id;
    order.cancelledAt = new Date();
    await order.save();
    res.json(order);
  } catch (err) {
    if (err.error?.description) return res.status(400).json({ message: err.error.description });
    next(err);
  }
};
