const Product = require('../models/Product');
const Category = require('../models/Category');

const buildQuery = (query, isAdmin) => {
  const q = {};
  if (!isAdmin) q.isActive = true;
  if (query.category) q.category = query.category;
  if (query.subcategory) q.subcategory = query.subcategory;
  if (query.search) {
    q.$or = [
      { name: new RegExp(query.search, 'i') },
      { description: new RegExp(query.search, 'i') }
    ];
  }
  if (query.minPrice) q.price = { ...q.price, $gte: Number(query.minPrice) };
  if (query.maxPrice) q.price = { ...(q.price || {}), $lte: Number(query.maxPrice) };
  if (query.soldOut === 'true') q.soldOut = true;
  if (query.soldOut === 'false') q.soldOut = false;
  return q;
};

exports.getFeatured = async (req, res, next) => {
  try {
    const products = await Product.find({ isActive: true, isFeatured: true })
      .populate('category', 'name slug')
      .populate('subcategory', 'name slug')
      .sort('heroOrder -createdAt')
      .limit(10)
      .lean();
    res.json({ products });
  } catch (err) {
    next(err);
  }
};

exports.getLanding = async (req, res, next) => {
  try {
    const isAdmin = req.user?.role === 'admin';
    const limitPerCategory = parseInt(req.query.limit) || 8;
    const parentCats = await Category.find(isAdmin ? {} : { isActive: true, parent: null })
      .sort('sortOrder name')
      .lean();
    const sections = [];
    for (const cat of parentCats) {
      const subIds = (await Category.find({ parent: cat._id }).select('_id').lean()).map((c) => c._id);
      const categoryIds = [cat._id, ...subIds];
      const products = await Product.find({
        category: { $in: categoryIds },
        ...(isAdmin ? {} : { isActive: true })
      })
        .populate('category', 'name slug')
        .populate('subcategory', 'name slug')
        .limit(limitPerCategory)
        .sort('-createdAt')
        .lean();
      const total = await Product.countDocuments({
        category: { $in: categoryIds },
        ...(isAdmin ? {} : { isActive: true })
      });
      if (products.length > 0 || total > 0) {
        sections.push({ category: cat, products, total });
      }
    }
    res.json({ sections });
  } catch (err) {
    next(err);
  }
};

exports.getAll = async (req, res, next) => {
  try {
    const isAdmin = req.user?.role === 'admin';
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 12;
    const skip = (page - 1) * limit;
    let filter = buildQuery(req.query, isAdmin);
    if (req.query.category) {
      const subIds = (await Category.find({ parent: req.query.category }).select('_id').lean()).map((c) => c._id);
      const categoryIds = [req.query.category, ...subIds];
      filter = { ...filter, category: { $in: categoryIds } };
    }
    const [products, total] = await Promise.all([
      Product.find(filter)
        .populate('category', 'name slug')
        .populate('subcategory', 'name slug')
        .skip(skip)
        .limit(limit)
        .sort('-createdAt'),
      Product.countDocuments(filter)
    ]);
    res.json({ products, total, page, totalPages: Math.ceil(total / limit) });
  } catch (err) {
    next(err);
  }
};

exports.getOne = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.id)
      .populate('category', 'name slug')
      .populate('subcategory', 'name slug');
    if (!product) return res.status(404).json({ message: 'Product not found' });
    const isAdmin = req.user?.role === 'admin';
    if (!isAdmin && !product.isActive) {
      return res.status(404).json({ message: 'Product not found' });
    }
    res.json(product);
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const product = await Product.create(req.body);
    res.status(201).json(product);
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const product = await Product.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true
    })
      .populate('category', 'name slug')
      .populate('subcategory', 'name slug');
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.json(product);
  } catch (err) {
    next(err);
  }
};

exports.delete = async (req, res, next) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.json({ message: 'Product deleted' });
  } catch (err) {
    next(err);
  }
};
