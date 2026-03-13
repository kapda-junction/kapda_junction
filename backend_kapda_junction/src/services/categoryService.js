const Category = require('../models/Category');

const categoryService = {
  async getAll() {
    return Category.find().sort({ name: 1 });
  },

  async getById(id) {
    const cat = await Category.findById(id);
    if (!cat) throw new Error('Category not found');
    return cat;
  },

  async create(data) {
    return Category.create(data);
  },

  async update(id, data) {
    const cat = await Category.findByIdAndUpdate(id, data, { new: true, runValidators: true });
    if (!cat) throw new Error('Category not found');
    return cat;
  },

  async delete(id) {
    const cat = await Category.findByIdAndDelete(id);
    if (!cat) throw new Error('Category not found');
    return cat;
  }
};

module.exports = categoryService;
