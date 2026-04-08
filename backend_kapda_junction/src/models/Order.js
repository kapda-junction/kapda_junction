const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  product: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
  name: String,
  price: Number,
  quantity: Number,
  size: String,
  color: String
});

const orderSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  items: [orderItemSchema],
  status: { type: String, enum: ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'], default: 'pending' },
  subtotal: { type: Number, default: null },
  discountAmount: { type: Number, default: 0 },
  coupon: { type: mongoose.Schema.Types.ObjectId, ref: 'Coupon', default: null },
  couponCode: { type: String, default: '' },
  totalAmount: { type: Number, required: true },
  shippingAddress: { type: mongoose.Schema.Types.Mixed, required: true },
  paymentMethod: { type: String, default: 'razorpay' },
  paymentStatus: { type: String, enum: ['pending', 'paid', 'failed', 'refunded', 'partially_refunded'], default: 'pending' },
  /** Set after reduceStock on successful capture — used so refund.processed does not inflate stock if nothing was deducted */
  stockDeducted: { type: Boolean, default: false },
  razorpayOrderId: String,
  razorpayPaymentId: String,
  razorpaySignature: String,
  // Refund tracking
  razorpayRefundId: String,
  refundStatus: { type: String, enum: ['', 'pending', 'processed', 'failed'], default: '' },
  refundAmount: Number,
  /** Last Razorpay / refund error text (audit) */
  refundLastError: { type: String, default: '' },
  /** Admin-only note when refund is manual or retried */
  refundNote: { type: String, default: '' },
  cancelReason: String,
  cancelledAt: Date,
  cancelledBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  /** Manual post / India Post — no courier API */
  shippingCarrier: { type: String, default: 'India Post' },
  /** Article / consignment / tracking number */
  shippingAwb: { type: String, default: '' },
  /** If India Post URL format changes, admin can paste full tracking URL */
  shippingTrackingUrlOverride: { type: String, default: '' },
  shippedAt: { type: Date, default: null }
}, { timestamps: true });

module.exports = mongoose.model('Order', orderSchema);
