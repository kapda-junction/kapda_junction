const User = require('../models/User');
const { sendToTokens } = require('./fcmService');

/**
 * Sends FCM to a customer's registered devices. Safe no-op if Firebase/user/tokens missing.
 * Does not throw; logs a warning on failure.
 */
async function sendPushToUserId(userId, { title, body, data = {} }) {
  if (!userId) return;
  try {
    const user = await User.findById(userId).select('fcmTokens');
    if (!user || !user.fcmTokens?.length) return;

    const tokens = [...new Set(user.fcmTokens.map((t) => t.token).filter(Boolean))];
    if (!tokens.length) return;

    const safeData = {};
    for (const [k, v] of Object.entries(data)) {
      if (v === undefined || v === null) continue;
      safeData[k] = String(v);
    }

    const result = await sendToTokens(tokens, {
      title: String(title || 'Kapda Junction').slice(0, 150),
      body: String(body || '').slice(0, 500),
      data: safeData
    });

    if (result.invalidTokens?.length) {
      await User.findByIdAndUpdate(userId, {
        $pull: { fcmTokens: { token: { $in: result.invalidTokens } } }
      });
    }
  } catch (e) {
    console.warn('[customerPush]', (e && e.message) || e);
  }
}

function notifyOrderPush(userId, orderId, title, body) {
  return sendPushToUserId(userId, {
    title,
    body,
    data: { screen: 'order', orderId: String(orderId || '') }
  });
}

function notifyReturnsPush(userId, title, body) {
  return sendPushToUserId(userId, {
    title,
    body,
    data: { screen: 'returns' }
  });
}

module.exports = {
  sendPushToUserId,
  notifyOrderPush,
  notifyReturnsPush
};
