const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema({
  code: { type: String, required: true, unique: true, trim: true, uppercase: true },
  description: { type: String, default: '' },
  type: { type: String, enum: ['percentage', 'fixed'], required: true },
  value: { type: Number, required: true, min: 0 },
  minCartValue: { type: Number, default: 0, min: 0 },
  maxDiscountAmount: { type: Number, default: null },
  categoryIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Category' }],
  productIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Product' }],
  firstOrderOnly: { type: Boolean, default: false },
  restrictedUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  usageLimitTotal: { type: Number, default: null },
  usageLimitPerUser: { type: Number, default: 1, min: 1 },
  usedCount: { type: Number, default: 0, min: 0 },
  startsAt: { type: Date, default: null },
  endsAt: { type: Date, default: null },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

couponSchema.pre('save', function (next) {
  if (this.code) this.code = String(this.code).trim().toUpperCase();
  next();
});

couponSchema.index({ isActive: 1, endsAt: 1 });

module.exports = mongoose.model('Coupon', couponSchema);
