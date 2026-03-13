const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    if (!token) throw new Error('Authentication required');
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'kapda-junction-secret');
    const user = await User.findById(decoded.id);
    if (!user) throw new Error('User not found');
    req.user = user;
    req.token = token;
    next();
  } catch (e) {
    res.status(401).json({ success: false, message: e.message });
  }
};

const optionalAuth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    if (token) {
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'kapda-junction-secret');
      const user = await User.findById(decoded.id);
      if (user) req.user = user;
    }
  } catch (_) {}
  next();
};

const authorize = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    return res.status(403).json({ success: false, message: 'Access denied' });
  }
  next();
};

module.exports = { protect, optionalAuth, authorize };
