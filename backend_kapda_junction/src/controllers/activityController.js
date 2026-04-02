const UserActivity = require('../models/UserActivity');

exports.trackSearch = async (req, res, next) => {
  try {
    if (!req.user) return res.json({ ok: true });
    const { query } = req.body;
    if (!query || query.trim().length < 2) return res.json({ ok: true });

    await UserActivity.create({ user: req.user.id, type: 'search', query: query.trim() });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
};

exports.trackView = async (req, res, next) => {
  try {
    if (!req.user) return res.json({ ok: true });
    const { productId, productName, productImage } = req.body;
    if (!productId) return res.json({ ok: true });

    await UserActivity.findOneAndUpdate(
      { user: req.user.id, type: 'view', productId },
      { $set: { productName, productImage, updatedAt: new Date() } },
      { upsert: true }
    );
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
};

exports.getRecentSearches = async (req, res, next) => {
  try {
    if (!req.user) return res.json({ searches: [] });
    const activities = await UserActivity.find({ user: req.user.id, type: 'search' })
      .sort({ createdAt: -1 }).limit(20).lean();

    const seen = new Set();
    const searches = [];
    for (const a of activities) {
      const key = a.query.toLowerCase();
      if (!seen.has(key)) { seen.add(key); searches.push(a.query); }
      if (searches.length >= 8) break;
    }
    res.json({ searches });
  } catch (err) {
    next(err);
  }
};

exports.getRecentViews = async (req, res, next) => {
  try {
    if (!req.user) return res.json({ products: [] });
    const activities = await UserActivity.find({ user: req.user.id, type: 'view' })
      .sort({ updatedAt: -1 }).limit(10).lean();

    const products = activities.map(a => ({
      id: a.productId,
      name: a.productName,
      image: a.productImage,
    }));
    res.json({ products });
  } catch (err) {
    next(err);
  }
};
