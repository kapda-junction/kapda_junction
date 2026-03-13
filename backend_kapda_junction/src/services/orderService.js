const Order = require('../models/Order');
const Product = require('../models/Product');

const createOrder = async (orderData, userId) => {
  const order = new Order({
    ...orderData,
    user: userId,
  });
  return order.save();
};

const getOrdersByUser = async (userId) => {
  return Order.find({ user: userId }).populate('items.product').sort({ createdAt: -1 });
};

const getAllOrders = async (filters = {}) => {
  return Order.find(filters).populate('user', 'name email').populate('items.product').sort({ createdAt: -1 });
};

const getOrderById = async (orderId, userId = null) => {
  const query = { _id: orderId };
  if (userId) query.user = userId;
  return Order.findOne(query).populate('items.product');
};

const updateOrderStatus = async (orderId, status) => {
  return Order.findByIdAndUpdate(orderId, { status }, { new: true });
};

module.exports = {
  createOrder,
  getOrdersByUser,
  getAllOrders,
  getOrderById,
  updateOrderStatus,
};
