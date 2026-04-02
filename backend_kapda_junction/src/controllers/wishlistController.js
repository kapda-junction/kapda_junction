const Wishlist = require('../models/Wishlist');
const Product = require('../models/Product');

exports.getWishlist = async (req, res, next) => {
  try {
    const wishlist = await Wishlist.findOne({ user: req.user.id })
      .populate('products', 'name price compareAtPrice images colorImages variants soldOut isActive isFeatured heroTag slug');
    const products = wishlist
      ? wishlist.products.filter(p => p && p.isActive)
      : [];
    res.json({ products });
  } catch (err) {
    next(err);
  }
};

exports.getWishlistIds = async (req, res, next) => {
  try {
    const wishlist = await Wishlist.findOne({ user: req.user.id }).select('products').lean();
    res.json({ productIds: wishlist ? wishlist.products.map(id => id.toString()) : [] });
  } catch (err) {
    next(err);
  }
};

exports.addToWishlist = async (req, res, next) => {
  try {
    const { productId } = req.params;
    const exists = await Product.exists({ _id: productId });
    if (!exists) return res.status(404).json({ message: 'Product not found' });

    const wishlist = await Wishlist.findOneAndUpdate(
      { user: req.user.id },
      { $addToSet: { products: productId } },
      { upsert: true, new: true }
    );
    res.json({ added: true, count: wishlist.products.length });
  } catch (err) {
    next(err);
  }
};

exports.removeFromWishlist = async (req, res, next) => {
  try {
    const { productId } = req.params;
    const wishlist = await Wishlist.findOneAndUpdate(
      { user: req.user.id },
      { $pull: { products: productId } },
      { new: true }
    );
    res.json({ removed: true, count: wishlist ? wishlist.products.length : 0 });
  } catch (err) {
    next(err);
  }
};
