const mongoose = require('mongoose');

const bannerSchema = new mongoose.Schema({
  image: { type: String, required: true },
  products: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Product' }],
  sortOrder: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

// Max 4 products per banner
bannerSchema.pre('save', function (next) {
  if (this.products && this.products.length > 4) {
    this.products = this.products.slice(0, 4);
  }
  next();
});

module.exports = mongoose.model('Banner', bannerSchema);
