const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const authService = {
  async register(data) {
    const { email, password, name, role = 'customer' } = data;
    const exists = await User.findOne({ email });
    if (exists) throw new Error('Email already registered');
    const user = await User.create({ email, password, name, role });
    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    return { user: { id: user._id, email: user.email, name: user.name, role: user.role }, token };
  },

  async login(email, password) {
    const user = await User.findOne({ email }).select('+password');
    if (!user) throw new Error('Invalid credentials');
    const valid = await bcrypt.compare(password, user.password);
    if (!valid) throw new Error('Invalid credentials');
    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    return { user: { id: user._id, email: user.email, name: user.name, role: user.role }, token };
  }
};

module.exports = authService;
