const Razorpay = require('razorpay');
const Order = require('../models/Order');
const ReturnRequest = require('../models/ReturnRequest');
const storePolicy = require('../services/storePolicyService');
const { notifyReturnsPush, notifyOrderPush, fetchOrderFirstImage } = require('../services/customerPushService');

const rzp = process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET
  ? new Razorpay({ key_id: process.env.RAZORPAY_KEY_ID, key_secret: process.env.RAZORPAY_KEY_SECRET })
  : null;
const TERMINAL_RETURN_STATUSES = ReturnRequest.TERMINAL_RETURN_STATUSES;
const RETURN_STATUSES = ReturnRequest.RETURN_STATUSES;

const MIN_REASON_DETAIL = 10;

function resolveOrderLine(order, line) {
  if (line.orderItemId) {
    const doc = order.items.id(line.orderItemId);
    return doc || null;
  }
  if (line.itemIndex != null && line.itemIndex >= 0 && line.itemIndex < order.items.length) {
    return order.items[line.itemIndex];
  }
  return null;
}

/** How many units of this line are already in non-terminal return requests */
async function qtyInOpenReturns(orderId, orderItemKey, excludeRequestId) {
  const filter = {
    order: orderId,
    status: { $nin: TERMINAL_RETURN_STATUSES },
    ...(excludeRequestId ? { _id: { $ne: excludeRequestId } } : {})
  };
  const requests = await ReturnRequest.find(filter);
  let sum = 0;
  for (const req of requests) {
    for (const it of req.items || []) {
      const key = it.orderItemId ? String(it.orderItemId) : `idx:${it.itemIndex}`;
      if (key === orderItemKey) sum += it.quantity || 0;
    }
  }
  return sum;
}

function lineKey(subDoc, index) {
  if (subDoc?._id) return String(subDoc._id);
  return `idx:${index}`;
}

function pushCopyForReturnStatus(status, type) {
  const ex = type === 'exchange';
  switch (status) {
    case 'approved':
      return {
        title: ex ? 'Exchange approved' : 'Return approved',
        body: 'Open the app for next steps on pickup or shipping.'
      };
    case 'rejected':
      return {
        title: 'Return update',
        body: 'We couldn\'t approve this request. See the reason in the Returns section.'
      };
    case 'pickup_scheduled':
      return {
        title: 'Pickup scheduled',
        body: 'Reverse pickup is booked. Please keep items packed and ready.'
      };
    case 'in_transit':
      return {
        title: 'Return in transit',
        body: 'Your return parcel is on the way back to us.'
      };
    case 'received':
      return {
        title: 'Items received',
        body: 'We received your return. Refund or exchange will follow shortly.'
      };
    case 'refund_processing':
      return {
        title: 'Refund processing',
        body: 'Your refund for this return is being processed.'
      };
    case 'refunded':
      if (type === 'order_cancel') {
        return {
          title: 'Refund sent',
          body: 'Your order-cancellation refund has been completed. Allow a few days for your bank/UPI.'
        };
      }
      return {
        title: 'Refund sent',
        body: 'Refund for your return has been completed. Allow a few days for your bank/UPI.'
      };
    case 'exchange_processing':
      return {
        title: 'Exchange in progress',
        body: 'We\'re preparing your replacement — we\'ll notify you when it ships.'
      };
    case 'exchange_shipped':
      return {
        title: 'Exchange shipped',
        body: 'Your replacement is on the way. Check the app for tracking details.'
      };
    case 'completed':
      return {
        title: ex ? 'Exchange completed' : 'Return completed',
        body: 'This return or exchange is closed. Thanks for shopping with us.'
      };
    default:
      return null;
  }
}

exports.list = async (req, res, next) => {
  try {
    const filter = req.user.role === 'admin' ? {} : { user: req.user.id };
    if (req.query.orderId) filter.order = req.query.orderId;
    const list = await ReturnRequest.find(filter)
      .populate(
        'order',
        'status totalAmount paymentStatus createdAt cancelReason cancelledAt cancelledBy refundStatus refundAmount'
      )
      .populate('user', 'name email')
      .sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    next(err);
  }
};

exports.getOne = async (req, res, next) => {
  try {
    const doc = await ReturnRequest.findById(req.params.id).populate('order').populate('user', 'name email');
    if (!doc) return res.status(404).json({ message: 'Return request not found' });
    const ownerId = doc.user?.id ? doc.user.id.toString() : doc.user.toString();
    if (req.user.role !== 'admin' && ownerId !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    res.json(doc);
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    if (!(await storePolicy.isReturnsEnabled())) {
      return res.status(403).json({
        message: 'Returns and exchanges are currently turned off. Please contact support.'
      });
    }

    const { orderId, type, items, reason, reasonDetail, exchangeFor, videoUrl } = req.body;
    if (!orderId || !type || !items?.length || !reason) {
      return res.status(400).json({ message: 'orderId, type, items, reason required' });
    }
    const detail = String(reasonDetail || '').trim();
    if (detail.length < MIN_REASON_DETAIL) {
      return res.status(400).json({
        message: `Please describe the issue in at least ${MIN_REASON_DETAIL} characters (required for review).`
      });
    }

    const videoRequired = await storePolicy.isReturnVideoRequired();
    const v = String(videoUrl || '').trim();
    if (videoRequired) {
      if (!v.startsWith('http')) {
        return res.status(400).json({
          message: 'A short product video is required — upload the clip using the app, then submit.'
        });
      }
    }

    if (!['return', 'exchange'].includes(type)) {
      return res.status(400).json({ message: 'type must be return or exchange' });
    }
    if (type === 'exchange' && (!exchangeFor?.size && !exchangeFor?.color)) {
      return res.status(400).json({ message: 'exchangeFor must include desired size or color' });
    }

    const order = await Order.findById(orderId).populate('items.product', 'images');
    if (!order) return res.status(404).json({ message: 'Order not found' });
    if (order.user.toString() !== req.user.id) return res.status(403).json({ message: 'Not authorized' });

    if (order.status !== 'delivered') {
      return res.status(400).json({ message: 'Returns are only available after delivery' });
    }
    if (order.paymentStatus !== 'paid') {
      return res.status(400).json({ message: 'Order must be paid' });
    }

    const normalizedItems = [];
    const seenKeys = new Set();
    for (const raw of items) {
      const qty = Math.max(1, parseInt(raw.quantity, 10) || 1);
      const line = resolveOrderLine(order, {
        orderItemId: raw.orderItemId,
        itemIndex: raw.itemIndex
      });
      if (!line) return res.status(400).json({ message: 'Invalid item reference in request' });
      const idx = order.items.indexOf(line);
      const key = lineKey(line, idx);
      if (seenKeys.has(key)) {
        return res.status(400).json({ message: 'Duplicate item in return request' });
      }
      seenKeys.add(key);
      const already = await qtyInOpenReturns(order._id, key, null);
      const lineQty = Math.max(1, parseInt(line.quantity, 10) || 1);
      if (already + qty > lineQty) {
        return res.status(400).json({ message: `Quantity too high for ${line.name || 'item'} (${lineQty} ordered, ${already} already in return/exchange)` });
      }
      if (line._id) {
        normalizedItems.push({ orderItemId: line._id, quantity: qty });
      } else {
        normalizedItems.push({ itemIndex: idx, quantity: qty });
      }
    }

    const activeOther = await ReturnRequest.findOne({
      order: order._id,
      user: req.user.id,
      status: { $nin: TERMINAL_RETURN_STATUSES }
    });
    if (activeOther) {
      return res.status(400).json({ message: 'You already have an open return or exchange for this order. Finish or cancel it first.' });
    }

    const doc = await ReturnRequest.create({
      user: req.user.id,
      order: order._id,
      type,
      items: normalizedItems,
      reason,
      reasonDetail: detail,
      videoUrl: videoRequired ? v : (v || ''),
      exchangeFor: type === 'exchange' ? {
        size: exchangeFor?.size || '',
        color: exchangeFor?.color || ''
      } : { size: '', color: '' },
      status: 'requested'
    });

    const populated = await ReturnRequest.findById(doc._id).populate('order', 'status totalAmount');
    notifyReturnsPush(
      req.user.id,
      type === 'exchange' ? 'Exchange requested' : 'Return requested',
      'We\'ve received your request and will review it shortly.',
      order?.items?.[0]?.product?.images?.[0]
    ).catch(() => {});
    res.status(201).json(populated);
  } catch (err) {
    next(err);
  }
};

exports.cancelMine = async (req, res, next) => {
  try {
    const doc = await ReturnRequest.findById(req.params.id);
    if (!doc) return res.status(404).json({ message: 'Return request not found' });
    if (doc.user.toString() !== req.user.id) return res.status(403).json({ message: 'Not authorized' });
    if (doc.status !== 'requested') {
      return res.status(400).json({ message: 'Only pending requests can be cancelled' });
    }
    doc.status = 'cancelled';
    await doc.save();
    res.json(doc);
  } catch (err) {
    next(err);
  }
};

/**
 * After admin approves an order_cancel request: Razorpay refund + mark order cancelled.
 * Webhook refund.processed finalises paymentStatus / stock like other refunds.
 */
async function fulfillOrderCancelAfterApproval(doc, adminUserId) {
  const order = await Order.findById(doc.order).populate('items.product', 'images');
  if (!order) throw new Error('Order not found');
  const img = order?.items?.[0]?.product?.images?.[0];
  if (order.status === 'cancelled') {
    doc.status = 'refunded';
    await doc.save();
    return;
  }
  if (!(order.paymentStatus === 'paid' && order.razorpayPaymentId)) {
    order.status = 'cancelled';
    order.cancelReason = doc.reasonDetail || doc.reason || 'Order cancellation approved';
    order.cancelledBy = adminUserId;
    order.cancelledAt = new Date();
    if (order.paymentStatus === 'pending') order.paymentStatus = 'failed';
    await order.save();
    doc.status = 'completed';
    await doc.save();
    notifyOrderPush(
      order.user,
      order._id,
      'Order cancelled',
      'Your cancellation was approved.',
      img
    ).catch(() => {});
    return;
  }
  if (!rzp) throw new Error('Payment service not configured');
  const amountPaise = Math.round((order.totalAmount || 0) * 100);
  const refund = await rzp.payments.refund(order.razorpayPaymentId, { amount: amountPaise });
  order.refundStatus = 'pending';
  order.razorpayRefundId = refund.id;
  order.refundAmount = order.totalAmount;
  order.refundLastError = '';
  order.cancelReason = doc.reasonDetail || doc.reason || 'Order cancellation approved';
  order.cancelledBy = adminUserId;
  order.cancelledAt = new Date();
  order.status = 'cancelled';
  await order.save();
  doc.status = 'refunded';
  doc.refundAmount = order.totalAmount;
  await doc.save();
  notifyOrderPush(
    order.user,
    order._id,
    'Refund started',
    'Your cancellation was approved. Refund is on the way — usually 5–7 working days.',
    img
  ).catch(() => {});
}

exports.update = async (req, res, next) => {
  try {
    const doc = await ReturnRequest.findById(req.params.id);
    if (!doc) return res.status(404).json({ message: 'Return request not found' });
    const prevStatus = doc.status;

    const {
      status,
      adminNote,
      rejectReason,
      pickupCourier,
      pickupAwb,
      pickupScheduledAt,
      refundAmount,
      exchangeAwb
    } = req.body;

    if (status != null && status !== doc.status) {
      if (!RETURN_STATUSES.includes(status)) {
        return res.status(400).json({ message: 'Invalid status' });
      }
      if (doc.status === 'requested' && !['approved', 'rejected'].includes(status)) {
        return res.status(400).json({
          message: 'This request is awaiting your decision. Approve or reject it first — only then can you set pickup/refund stages.'
        });
      }
      if (status === 'approved') {
        const needVideo = await storePolicy.isReturnVideoRequired();
        if (needVideo && (!doc.videoUrl || !String(doc.videoUrl).startsWith('http'))) {
          return res.status(400).json({
            message: 'Cannot approve: customer proof video is missing or invalid.'
          });
        }
        if (doc.type === 'order_cancel') {
          doc.status = 'approved';
          await doc.save();
          try {
            await fulfillOrderCancelAfterApproval(doc, req.user.id);
          } catch (err) {
            doc.status = 'requested';
            await doc.save();
            if (err.error?.description) return res.status(400).json({ message: err.error.description });
            return res.status(400).json({ message: err.message || 'Refund failed' });
          }
          const populated = await ReturnRequest.findById(doc._id)
            .populate(
              'order',
              'status totalAmount paymentStatus createdAt cancelReason cancelledAt cancelledBy refundStatus refundAmount'
            )
            .populate('user', 'name email');
          res.json(populated);
          const copy = pushCopyForReturnStatus(doc.status, doc.type);
          if (copy) {
            fetchOrderFirstImage(doc.order).then((img) => {
              notifyReturnsPush(doc.user, copy.title, copy.body, img).catch(() => {});
            }).catch(() => {});
          }
          return;
        }
      }
      doc.status = status;
    }
    if (adminNote !== undefined) doc.adminNote = adminNote;
    if (rejectReason !== undefined) doc.rejectReason = rejectReason;
    if (pickupCourier !== undefined) doc.pickupCourier = pickupCourier;
    if (pickupAwb !== undefined) doc.pickupAwb = pickupAwb;
    if (pickupScheduledAt !== undefined) doc.pickupScheduledAt = pickupScheduledAt ? new Date(pickupScheduledAt) : null;
    if (refundAmount !== undefined) doc.refundAmount = refundAmount;
    if (exchangeAwb !== undefined) doc.exchangeAwb = exchangeAwb;

    await doc.save();
    const populated = await ReturnRequest.findById(doc._id)
      .populate('order')
      .populate('user', 'name email');
    res.json(populated);

    if (doc.status !== prevStatus) {
      const copy = pushCopyForReturnStatus(doc.status, doc.type);
      if (copy) {
        fetchOrderFirstImage(doc.order).then((img) => {
          notifyReturnsPush(doc.user, copy.title, copy.body, img).catch(() => {});
        }).catch(() => {});
      }
    }
  } catch (err) {
    next(err);
  }
};
