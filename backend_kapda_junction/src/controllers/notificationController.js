const User = require('../models/User');
const DeviceToken = require('../models/DeviceToken');
const Product = require('../models/Product');
const { sendToTokens } = require('../services/fcmService');

function getProductShareUrl(productId) {
  const base = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
  return `${base.replace(/\/$/, '')}/share/product/${productId}`;
}

async function resolveAudienceTokens({ audienceType, userIds }) {
  if (audienceType === 'broadcast') {
    const users = await User.find({
      role: 'customer',
      'fcmTokens.0': { $exists: true }
    }).select('_id email name fcmTokens');
    const userTokens = users.flatMap((u) => (u.fcmTokens || []).map((t) => t.token).filter(Boolean));

    // Also include anonymous (non-logged-in) device tokens
    const anonDocs = await DeviceToken.find().select('token').lean();
    const anonTokens = anonDocs.map((d) => d.token).filter(Boolean);

    // Deduplicate (a token that logged in will have been removed from DeviceToken,
    // but guard anyway)
    const tokens = [...new Set([...userTokens, ...anonTokens])];
    return { users, tokens };
  }

  if (audienceType === 'users') {
    const safeIds = (userIds || []).map(String).filter(Boolean);
    const users = await User.find({
      _id: { $in: safeIds },
      'fcmTokens.0': { $exists: true }
    }).select('_id email name fcmTokens');
    const tokens = users.flatMap((u) => (u.fcmTokens || []).map((t) => t.token).filter(Boolean));
    return { users, tokens };
  }

  throw new Error('Unsupported audienceType');
}

exports.listAudience = async (req, res, next) => {
  try {
    const search = String(req.query.search || '').trim();
    const limitRaw = Number(req.query.limit || 50);
    const limit = Number.isFinite(limitRaw) ? Math.min(Math.max(limitRaw, 1), 200) : 50;

    const filter = {
      role: 'customer',
      ...(search
        ? {
            $or: [
              { name: new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i') },
              { email: new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i') }
            ]
          }
        : {})
    };

    const users = await User.find(filter)
      .select('name email role fcmTokens createdAt')
      .sort('-createdAt')
      .limit(limit)
      .lean();

    const out = users.map((u) => ({
      id: String(u._id),
      name: u.name || '',
      email: u.email || '',
      role: u.role || 'customer',
      tokenCount: (u.fcmTokens || []).length,
      hasToken: (u.fcmTokens || []).length > 0
    }));

    res.json({ users: out });
  } catch (err) {
    next(err);
  }
};

exports.sendNotification = async (req, res, next) => {
  try {
    const {
      audienceType = 'broadcast',
      userIds = [],
      productId,
      title,
      body,
      data,
      imageUrl
    } = req.body || {};

    if (audienceType === 'users' && (!Array.isArray(userIds) || userIds.length === 0)) {
      return res.status(400).json({
        message: 'For users audience, userIds must be a non-empty array'
      });
    }

    let product = null;
    if (productId) {
      product = await Product.findById(productId).select('name price images').lean();
      if (!product) return res.status(404).json({ message: 'Product not found' });
    }

    const finalTitle = String(title || '').trim() || (product ? 'New product just dropped!' : '');
    const finalBody =
      String(body || '').trim() ||
      (product ? `${product.name} is now available. Tap to view.` : '');

    if (!finalTitle || !finalBody) {
      return res.status(400).json({ message: 'title and body are required' });
    }

    const { users, tokens } = await resolveAudienceTokens({
      audienceType,
      userIds
    });

    if (!tokens.length) {
      return res.status(400).json({
        message: 'No FCM tokens found for selected audience'
      });
    }

    const mergedData = {
      ...(data && typeof data === 'object' ? data : {}),
      ...(product ? { productId: String(product._id), shareUrl: getProductShareUrl(product._id) } : {})
    };

    const result = await sendToTokens(tokens, {
      title: finalTitle,
      body: finalBody,
      data: mergedData,
      imageUrl: String(imageUrl || '').trim() || product?.images?.[0]
    });

    if (result.invalidTokens.length) {
      await Promise.all([
        User.updateMany({}, { $pull: { fcmTokens: { token: { $in: result.invalidTokens } } } }),
        DeviceToken.deleteMany({ token: { $in: result.invalidTokens } })
      ]);
    }

    res.json({
      ok: true,
      audienceType,
      targetedUsers: users.length,
      targetedTokens: tokens.length,
      sentCount: result.sentCount,
      failureCount: result.failureCount,
      cleanedInvalidTokens: result.invalidTokens.length,
      product: product
        ? { id: String(product._id), name: product.name, image: product.images?.[0] }
        : null
    });
  } catch (err) {
    next(err);
  }
};

exports.sendUserNotification = async (req, res, next) => {
  req.body = {
    ...req.body,
    audienceType: 'users',
    userIds: req.body.userId ? [req.body.userId] : req.body.userIds
  };
  return exports.sendNotification(req, res, next);
};
