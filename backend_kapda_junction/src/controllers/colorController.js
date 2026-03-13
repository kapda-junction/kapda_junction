const Color = require('../models/Color');

exports.getAll = async (req, res, next) => {
  try {
    const colors = await Color.find().sort('name');
    res.json(colors);
  } catch (err) {
    next(err);
  }
};

exports.getOne = async (req, res, next) => {
  try {
    const color = await Color.findById(req.params.id);
    if (!color) return res.status(404).json({ message: 'Color not found' });
    res.json(color);
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const color = await Color.create(req.body);
    res.status(201).json(color);
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const color = await Color.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!color) return res.status(404).json({ message: 'Color not found' });
    res.json(color);
  } catch (err) {
    next(err);
  }
};

exports.delete = async (req, res, next) => {
  try {
    const color = await Color.findByIdAndDelete(req.params.id);
    if (!color) return res.status(404).json({ message: 'Color not found' });
    res.json({ message: 'Color deleted' });
  } catch (err) {
    next(err);
  }
};
