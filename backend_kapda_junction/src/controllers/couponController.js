const Coupon = require('../models/Coupon');
const {
  buildCartLinesFromRequestItems,
  validateAndApply,
  normalizeCode,
  eligibleSubtotalForCoupon
} = require('../services/couponService');

exports.list = async (req, res, next) => {
  try {
    const coupons = await Coupon.find().sort({ createdAt: -1 });
    res.json(coupons);
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const body = { ...req.body };
    if (body.code) body.code = normalizeCode(body.code);
    const coupon = await Coupon.create(body);
    res.status(201).json(coupon);
  } catch (err) {
    if (err.code === 11000) return res.status(400).json({ message: 'Coupon code already exists' });
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const body = { ...req.body };
    if (body.code != null) body.code = normalizeCode(body.code);
    const coupon = await Coupon.findByIdAndUpdate(req.params.id, body, { new: true, runValidators: true });
    if (!coupon) return res.status(404).json({ message: 'Coupon not found' });
    res.json(coupon);
  } catch (err) {
    if (err.code === 11000) return res.status(400).json({ message: 'Coupon code already exists' });
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const coupon = await Coupon.findByIdAndDelete(req.params.id);
    if (!coupon) return res.status(404).json({ message: 'Coupon not found' });
    res.json({ message: 'Deleted' });
  } catch (err) {
    next(err);
  }
};

/** Customer: preview discount — totals are authoritative on create-payment */
exports.validate = async (req, res, next) => {
  try {
    const { items, couponCode } = req.body;
    const built = await buildCartLinesFromRequestItems(items);
    if (built.error) return res.status(400).json({ message: built.error });

    const applied = await validateAndApply(req.user.id, built.lines, built.subtotal, couponCode);
    if (applied.error) return res.status(400).json({ message: applied.error });

    const elig = applied.coupon
      ? Math.round(eligibleSubtotalForCoupon(built.lines, applied.coupon) * 100) / 100
      : built.subtotal;
    res.json({
      subtotal: built.subtotal,
      eligibleSubtotal: elig,
      discountAmount: applied.discountAmount || 0,
      total: applied.total,
      couponCode: applied.coupon ? applied.coupon.code : null,
      couponDescription: applied.coupon ? applied.coupon.description : null
    });
  } catch (err) {
    next(err);
  }
};
