const mongoose = require('mongoose');

const activitySchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  type: { type: String, enum: ['search', 'view'], required: true },
  query: String,
  productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
  productName: String,
  productImage: String,
}, { timestamps: true });

activitySchema.index({ user: 1, type: 1, createdAt: -1 });

module.exports = mongoose.model('UserActivity', activitySchema);
