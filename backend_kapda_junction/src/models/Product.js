const mongoose = require('mongoose');

const variantSchema = new mongoose.Schema({
  color: { type: String, required: true },
  size: { type: String, required: true },
  stock: { type: Number, default: 0, min: 0 },
  sku: { type: String, unique: true, sparse: true }
}, { _id: true });

const productSchema = new mongoose.Schema({
  name: { type: String, required: true },
  slug: { type: String },
  description: { type: String },
  price: { type: Number, required: true },
  compareAtPrice: Number,
  category: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', required: true },
  subcategory: { type: mongoose.Schema.Types.ObjectId, ref: 'Category' },
  images: [{ type: String }],
  colorImages: [{
    color: { type: String, required: true },
    images: [{ type: String }]
  }],
  variants: [variantSchema],
  embedding: [Number],
  soldOut: { type: Boolean, default: false },
  isActive: { type: Boolean, default: true },
  isFeatured: { type: Boolean, default: false },
  heroTag: { type: String, default: '' },
  heroOrder: { type: Number, default: 0 }
}, { timestamps: true });

productSchema.virtual('totalStock').get(function () {
  return this.variants?.reduce((s, v) => s + (v.stock || 0), 0) ?? 0;
});

function genSku(name, color, size) {
  const n = (name || '').replace(/\s+/g, '').slice(0, 3).toUpperCase();
  const c = (color || '').replace(/\s+/g, '').slice(0, 2).toUpperCase();
  const s = (size || '').replace(/\s+/g, '').slice(0, 2).toUpperCase();
  const rand = Math.floor(1000 + Math.random() * 9000);
  return `${n}${c}${s}-${rand}`;
}

productSchema.pre('save', function (next) {
  if (!this.slug) this.slug = this.name.toLowerCase().replace(/\s+/g, '-').concat('-', Date.now());
  // Auto-generate SKU for variants that don't have one
  if (this.variants) {
    this.variants.forEach(v => {
      if (!v.sku) v.sku = genSku(this.name, v.color, v.size);
    });
  }
  const total = this.variants?.reduce((s, v) => s + (v.stock || 0), 0) ?? 0;
  this.soldOut = total === 0;
  next();
});

productSchema.index({ category: 1, isActive: 1 });
productSchema.index({ category: 1, isActive: 1, createdAt: -1 });
productSchema.index({ subcategory: 1, isActive: 1 });
productSchema.index({ name: 'text', description: 'text' });

module.exports = mongoose.model('Product', productSchema);
