const mongoose = require('mongoose');

const STATUSES = ['pending', 'approved', 'rejected'];

const reviewSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  product: { type: mongoose.Schema.Types.ObjectId, ref: 'Product', required: true },
  order: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', required: true },
  rating: { type: Number, required: true, min: 1, max: 5 },
  title: { type: String, default: '' },
  body: { type: String, default: '' },
  status: { type: String, enum: STATUSES, default: 'pending' },
  adminNote: { type: String, default: '' }
}, { timestamps: true });

reviewSchema.index({ product: 1, status: 1, createdAt: -1 });
reviewSchema.index({ order: 1, product: 1, user: 1 }, { unique: true });

const Review = mongoose.model('Review', reviewSchema);
Review.STATUSES = STATUSES;
module.exports = Review;
