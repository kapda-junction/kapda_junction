const Category = require('../models/Category');

const adminFilter = (req) => (req.user && req.user.role === 'admin' ? {} : { isActive: true });

exports.getAll = async (req, res, next) => {
  try {
    const showAll = req.user?.role === 'admin';
    const filter = showAll ? {} : { isActive: true };
    const parentOnly = req.query.parentOnly === 'true';
    let query = Category.find(filter).populate('parent', 'name slug').sort('sortOrder name');
    if (parentOnly) query = query.where('parent').exists(false);
    const categories = await query;
    res.json(categories);
  } catch (err) {
    next(err);
  }
};

exports.getTree = async (req, res, next) => {
  try {
    const showAll = req.user?.role === 'admin';
    const filter = showAll ? {} : { isActive: true };
    const top = await Category.find({ ...filter, parent: null }).populate('parent').sort('sortOrder name');
    const withChildren = await Promise.all(
      top.map(async (c) => {
        const children = await Category.find({ ...filter, parent: c._id }).sort('sortOrder name');
        return { ...c.toObject(), children };
      })
    );
    res.json(withChildren);
  } catch (err) {
    next(err);
  }
};

exports.getOne = async (req, res, next) => {
  try {
    const category = await Category.findById(req.params.id).populate('parent', 'name slug');
    if (!category) return res.status(404).json({ message: 'Category not found' });
    res.json(category);
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const category = await Category.create(req.body);
    res.status(201).json(category);
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const category = await Category.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!category) return res.status(404).json({ message: 'Category not found' });
    res.json(category);
  } catch (err) {
    next(err);
  }
};

exports.delete = async (req, res, next) => {
  try {
    const category = await Category.findByIdAndDelete(req.params.id);
    if (!category) return res.status(404).json({ message: 'Category not found' });
    res.json({ message: 'Category deleted' });
  } catch (err) {
    next(err);
  }
};
