const Banner = require('../models/Banner');

exports.getAll = async (req, res, next) => {
  try {
    const banners = await Banner.find()
      .populate('products', 'name price images _id')
      .sort('sortOrder createdAt')
      .lean();
    res.json(banners);
  } catch (err) {
    next(err);
  }
};

exports.getActive = async (req, res, next) => {
  try {
    const banners = await Banner.find({ isActive: true })
      .populate('products', 'name price images _id')
      .sort('sortOrder createdAt')
      .limit(10)
      .lean();
    res.json({ banners });
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const products = (req.body.products || []).slice(0, 4);
    const banner = await Banner.create({
      image: req.body.image,
      products,
      sortOrder: req.body.sortOrder ?? 0,
      isActive: req.body.isActive !== false
    });
    const populated = await Banner.findById(banner._id).populate('products', 'name price images').lean();
    res.status(201).json(populated);
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const products = (req.body.products || []).slice(0, 4);
    const update = {
      ...(req.body.image != null && { image: req.body.image }),
      ...(req.body.products != null && { products: products }),
      ...(req.body.sortOrder != null && { sortOrder: req.body.sortOrder }),
      ...(req.body.isActive != null && { isActive: req.body.isActive })
    };
    const banner = await Banner.findByIdAndUpdate(req.params.id, update, {
      new: true,
      runValidators: true
    })
      .populate('products', 'name price images _id')
      .lean();
    if (!banner) return res.status(404).json({ message: 'Banner not found' });
    res.json(banner);
  } catch (err) {
    next(err);
  }
};

exports.delete = async (req, res, next) => {
  try {
    const banner = await Banner.findByIdAndDelete(req.params.id);
    if (!banner) return res.status(404).json({ message: 'Banner not found' });
    res.json({ message: 'Banner deleted' });
  } catch (err) {
    next(err);
  }
};
