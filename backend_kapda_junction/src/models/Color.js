const mongoose = require('mongoose');

const colorSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true, unique: true },
  sortOrder: { type: Number, default: 0 },
}, { timestamps: true });

colorSchema.index({ name: 1 });
module.exports = mongoose.model('Color', colorSchema);
