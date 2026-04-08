const mongoose = require('mongoose');
const Review = require('../models/Review');
const Order = require('../models/Order');
const Product = require('../models/Product');

exports.listForProduct = async (req, res, next) => {
  try {
    const productId = req.params.productId;
    const list = await Review.find({ product: productId, status: 'approved' })
      .populate('user', 'name')
      .sort('-createdAt')
      .limit(100)
      .lean();
    if (!mongoose.isValidObjectId(productId)) {
      return res.status(400).json({ message: 'Invalid product id' });
    }
    const avg = await Review.aggregate([
      { $match: { product: new mongoose.Types.ObjectId(productId), status: 'approved' } },
      { $group: { _id: null, avg: { $avg: '$rating' }, count: { $sum: 1 } } }
    ]);
    const summary = avg[0] || { avg: 0, count: 0 };
    res.json({
      reviews: list.map((r) => ({
        id: r._id,
        rating: r.rating,
        title: r.title,
        body: r.body,
        userName: r.user?.name || 'Customer',
        createdAt: r.createdAt
      })),
      averageRating: Math.round((summary.avg || 0) * 10) / 10,
      reviewCount: summary.count || 0
    });
  } catch (err) {
    next(err);
  }
};

/** Customer: one review per (order + product). Order must be delivered & paid. */
exports.create = async (req, res, next) => {
  try {
    const { orderId, productId, rating, title, body } = req.body || {};
    if (!orderId || !productId || rating == null) {
      return res.status(400).json({ message: 'orderId, productId, rating required' });
    }
    const rNum = Number(rating);
    if (!Number.isFinite(rNum) || rNum < 1 || rNum > 5) {
      return res.status(400).json({ message: 'rating must be 1–5' });
    }

    const order = await Order.findById(orderId);
    if (!order) return res.status(404).json({ message: 'Order not found' });
    if (order.user.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    if (order.status !== 'delivered' || order.paymentStatus !== 'paid') {
      return res.status(400).json({ message: 'You can review only after the order is delivered and paid' });
    }

    const hasProduct = order.items.some((it) => {
      const pid = it.product?._id || it.product;
      return pid && pid.toString() === String(productId);
    });
    if (!hasProduct) return res.status(400).json({ message: 'This product was not in that order' });

    const product = await Product.findById(productId);
    if (!product) return res.status(404).json({ message: 'Product not found' });

    const review = await Review.create({
      user: req.user.id,
      product: productId,
      order: orderId,
      rating: Math.round(rNum),
      title: String(title || '').trim().slice(0, 120),
      body: String(body || '').trim().slice(0, 2000),
      status: 'pending'
    });
    res.status(201).json(review);
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ message: 'You already submitted a review for this item on this order' });
    }
    next(err);
  }
};

/** My reviews (customer) */
exports.mine = async (req, res, next) => {
  try {
    const list = await Review.find({ user: req.user.id })
      .populate('product', 'name images')
      .sort('-createdAt')
      .lean();
    res.json(list);
  } catch (err) {
    next(err);
  }
};

/** Admin — moderate */
exports.adminList = async (req, res, next) => {
  try {
    const q = {};
    if (req.query.status) q.status = req.query.status;
    const list = await Review.find(q)
      .populate('user', 'name email')
      .populate('product', 'name')
      .populate('order', 'status totalAmount')
      .sort('-createdAt')
      .limit(200)
      .lean();
    res.json(list);
  } catch (err) {
    next(err);
  }
};

exports.adminUpdate = async (req, res, next) => {
  try {
    const { status, adminNote } = req.body || {};
    if (!['pending', 'approved', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'status must be pending, approved, or rejected' });
    }
    const doc = await Review.findByIdAndUpdate(
      req.params.id,
      {
        status,
        adminNote: adminNote !== undefined ? String(adminNote).slice(0, 500) : undefined
      },
      { new: true }
    ).populate('user', 'name email').populate('product', 'name');
    if (!doc) return res.status(404).json({ message: 'Review not found' });
    res.json(doc);
  } catch (err) {
    next(err);
  }
};
