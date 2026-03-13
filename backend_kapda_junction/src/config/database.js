const mongoose = require('mongoose');

let cached = null;

const connectDB = async () => {
  if (cached) return cached;
  const uri = process.env.MONGODB_URI || 'mongodb+srv://kapdajunction:YOUR_PASSWORD@cluster0.o2gaoxi.mongodb.net/kapda_junction?retryWrites=true&w=majority';
  cached = await mongoose.connect(uri);
  return cached;
};

module.exports = connectDB;
