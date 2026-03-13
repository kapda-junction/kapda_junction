const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema({
  name: { type: String, required: true },
  slug: { type: String, unique: true },
  description: String,
  image: String,
  parent: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', default: null },
  metadata: {
    metaTitle: String,
    metaDescription: String,
    keywords: [String]
  },
  sortOrder: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

categorySchema.index({ parent: 1, isActive: 1 });
categorySchema.pre('save', function (next) {
  if (!this.slug) this.slug = this.name.toLowerCase().replace(/\s+/g, '-').concat('-', Date.now());
  next();
});

module.exports = mongoose.model('Category', categorySchema);
