const Coupon = require('../models/Coupon');
const Order = require('../models/Order');
const Product = require('../models/Product');

function normalizeCode(code) {
  return String(code || '').trim().toUpperCase();
}

/**
 * Resolve cart lines using DB prices and categories. Each line includes `category` for eligibility (stripped before save).
 */
async function buildCartLinesFromRequestItems(items) {
  if (!Array.isArray(items) || items.length === 0) {
    return { error: 'Cart is empty' };
  }
  const ids = [...new Set(items.map((i) => i.product).filter(Boolean))];
  const products = await Product.find({ _id: { $in: ids }, isActive: true }).select('name price category');
  const map = new Map(products.map((p) => [p._id.toString(), p]));

  const lines = [];
  let subtotal = 0;

  for (const it of items) {
    const pid = String(it.product);
    const p = map.get(pid);
    if (!p) {
      return { error: 'One or more products are invalid or unavailable' };
    }
    const qty = Math.max(1, parseInt(it.quantity, 10) || 1);
    const lineTotal = p.price * qty;
    subtotal += lineTotal;
    lines.push({
      product: p._id,
      name: p.name,
      price: p.price,
      quantity: qty,
      size: it.size || '',
      color: it.color || '',
      category: p.category
    });
  }

  subtotal = Math.round(subtotal * 100) / 100;
  return { lines, subtotal };
}

function eligibleSubtotalForCoupon(lines, coupon) {
  if (coupon.productIds?.length) {
    const set = new Set(coupon.productIds.map((id) => id.toString()));
    return lines
      .filter((l) => set.has(l.product.toString()))
      .reduce((s, l) => s + l.price * l.quantity, 0);
  }
  if (coupon.categoryIds?.length) {
    const set = new Set(coupon.categoryIds.map((id) => id.toString()));
    return lines
      .filter((l) => l.category && set.has(l.category.toString()))
      .reduce((s, l) => s + l.price * l.quantity, 0);
  }
  return lines.reduce((s, l) => s + l.price * l.quantity, 0);
}

function computeDiscountAmount(eligibleSubtotal, coupon) {
  if (eligibleSubtotal <= 0) return 0;
  let discount = 0;
  if (coupon.type === 'percentage') {
    discount = (eligibleSubtotal * coupon.value) / 100;
    if (coupon.maxDiscountAmount != null && coupon.maxDiscountAmount > 0) {
      discount = Math.min(discount, coupon.maxDiscountAmount);
    }
  } else {
    discount = Math.min(coupon.value, eligibleSubtotal);
  }
  return Math.round(discount * 100) / 100;
}

/**
 * @returns {Promise<{ discountAmount: number, total: number, coupon: object|null, error?: string }>}
 */
async function validateAndApply(userId, lines, subtotal, couponCode) {
  const code = normalizeCode(couponCode);
  if (!code) {
    return { discountAmount: 0, total: subtotal, coupon: null };
  }

  const coupon = await Coupon.findOne({ code, isActive: true });
  if (!coupon) return { error: 'Invalid or inactive coupon' };

  const now = new Date();
  if (coupon.startsAt && now < coupon.startsAt) return { error: 'This coupon is not active yet' };
  if (coupon.endsAt && now > coupon.endsAt) return { error: 'This coupon has expired' };

  if (coupon.usageLimitTotal != null && coupon.usedCount >= coupon.usageLimitTotal) {
    return { error: 'This coupon has reached its usage limit' };
  }

  if (coupon.restrictedUser && coupon.restrictedUser.toString() !== String(userId)) {
    return { error: 'This coupon is not valid for your account' };
  }

  if (coupon.firstOrderOnly) {
    const prev = await Order.countDocuments({
      user: userId,
      paymentStatus: 'paid'
    });
    if (prev > 0) return { error: 'This offer is only for your first paid order' };
  }

  const perUserLimit = coupon.usageLimitPerUser ?? 1;
  const userUses = await Order.countDocuments({
    user: userId,
    coupon: coupon._id,
    paymentStatus: 'paid'
  });
  if (userUses >= perUserLimit) return { error: 'You have already used this coupon' };

  const elig = Math.round(eligibleSubtotalForCoupon(lines, coupon) * 100) / 100;

  const hasScope =
    (coupon.productIds && coupon.productIds.length > 0) ||
    (coupon.categoryIds && coupon.categoryIds.length > 0);
  if (hasScope && elig <= 0) {
    return { error: 'No items in your cart qualify for this coupon' };
  }

  const minCart = coupon.minCartValue ?? 0;
  if (elig < minCart) {
    return {
      error: `Minimum ₹${minCart} of eligible items required (currently ₹${elig})`
    };
  }

  const discountAmount = computeDiscountAmount(elig, coupon);
  const total = Math.max(0, Math.round((subtotal - discountAmount) * 100) / 100);

  return { discountAmount, total, coupon };
}

function orderItemsForDb(lines) {
  return lines.map(({ category, ...rest }) => rest);
}

module.exports = {
  normalizeCode,
  buildCartLinesFromRequestItems,
  validateAndApply,
  eligibleSubtotalForCoupon,
  orderItemsForDb
};
