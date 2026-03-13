const Product = require('../models/Product');

const productService = {
  async getAll(filters = {}) {
    const { category, search, minPrice, maxPrice } = filters;
    const query = {};
    if (category) query.category = category;
    if (search) query.$or = [
      { name: { $regex: search, $options: 'i' } },
      { description: { $regex: search, $options: 'i' } }
    ];
    if (minPrice != null) query.price = query.price || {}; query.price.$gte = minPrice;
    if (maxPrice != null) query.price = query.price || {}; query.price.$lte = maxPrice;
    return Product.find(query).populate('category', 'name').sort({ createdAt: -1 });
  },

  async getById(id) {
    const prod = await Product.findById(id).populate('category', 'name');
    if (!prod) throw new Error('Product not found');
    return prod;
  },

  async create(data) {
    return Product.create(data);
  },

  async update(id, data) {
    const prod = await Product.findByIdAndUpdate(id, data, { new: true, runValidators: true });
    if (!prod) throw new Error('Product not found');
    return prod;
  },

  async delete(id) {
    const prod = await Product.findByIdAndDelete(id);
    if (!prod) throw new Error('Product not found');
    return prod;
  }
};

module.exports = productService;
