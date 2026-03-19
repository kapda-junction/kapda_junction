const Cart = require('../models/Cart');
const Product = require('../models/Product');

exports.get = async (req, res, next) => {
  try {
    let cart = await Cart.findOne({ user: req.user.id }).populate('items.product', 'name price images soldOut isActive');
    if (!cart) {
      cart = await Cart.create({ user: req.user.id, items: [] });
    }
    // Filter out deleted/inactive products
    const validItems = (cart.items || []).filter(i => i.product && i.product.isActive);
    if (validItems.length !== (cart.items?.length || 0)) {
      cart.items = validItems;
      await cart.save();
    }
    res.json(cart);
  } catch (err) {
    next(err);
  }
};

exports.put = async (req, res, next) => {
  try {
    const { items } = req.body;
    if (!Array.isArray(items)) {
      return res.status(400).json({ message: 'items must be an array' });
    }
    let cart = await Cart.findOne({ user: req.user.id });
    if (!cart) {
      cart = new Cart({ user: req.user.id, items: [] });
    }
    // Validate product ids exist
    const productIds = [...new Set(items.map(i => i.product).filter(Boolean))];
    if (productIds.length > 0) {
      const products = await Product.find({ _id: { $in: productIds }, isActive: true }).select('_id');
      const validIds = new Set(products.map(p => p._id.toString()));
      cart.items = items.filter(i => validIds.has(String(i.product))).map(i => ({
        product: i.product,
        quantity: Math.max(1, parseInt(i.quantity) || 1),
        color: i.color || '',
        size: i.size || ''
      }));
    } else {
      cart.items = [];
    }
    cart.updatedAt = new Date();
    await cart.save();
    await cart.populate('items.product', 'name price images soldOut isActive');
    res.json(cart);
  } catch (err) {
    next(err);
  }
};
