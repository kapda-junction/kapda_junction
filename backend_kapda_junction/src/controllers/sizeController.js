const Size = require('../models/Size');

exports.getAll = async (req, res, next) => {
  try {
    const sizes = await Size.find().sort('sortOrder name');
    res.json(sizes);
  } catch (err) {
    next(err);
  }
};

exports.getOne = async (req, res, next) => {
  try {
    const size = await Size.findById(req.params.id);
    if (!size) return res.status(404).json({ message: 'Size not found' });
    res.json(size);
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const size = await Size.create(req.body);
    res.status(201).json(size);
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const size = await Size.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!size) return res.status(404).json({ message: 'Size not found' });
    res.json(size);
  } catch (err) {
    next(err);
  }
};

exports.delete = async (req, res, next) => {
  try {
    const size = await Size.findByIdAndDelete(req.params.id);
    if (!size) return res.status(404).json({ message: 'Size not found' });
    res.json({ message: 'Size deleted' });
  } catch (err) {
    next(err);
  }
};
