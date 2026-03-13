const mongoose = require('mongoose');

const sizeSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true, unique: true },
  sortOrder: { type: Number, default: 0 },
}, { timestamps: true });

sizeSchema.index({ name: 1 });
module.exports = mongoose.model('Size', sizeSchema);
