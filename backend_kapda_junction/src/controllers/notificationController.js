const User = require('../models/User');
const { sendToTokens } = require('../services/fcmService');

exports.sendUserNotification = async (req, res, next) => {
  try {
    const { userId, title, body, data, imageUrl } = req.body;

    if (!userId || !title || !body) {
      return res.status(400).json({
        message: 'userId, title and body are required'
      });
    }

    const user = await User.findById(userId).select('name email fcmTokens');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const tokens = (user.fcmTokens || [])
      .map((t) => t.token)
      .filter(Boolean);

    if (!tokens.length) {
      return res.status(400).json({
        message: 'No FCM tokens found for this user',
        user: { id: user._id, email: user.email }
      });
    }

    const result = await sendToTokens(tokens, { title, body, data, imageUrl });

    if (result.invalidTokens.length) {
      await User.findByIdAndUpdate(userId, {
        $pull: { fcmTokens: { token: { $in: result.invalidTokens } } }
      });
    }

    res.json({
      ok: true,
      user: { id: user._id, email: user.email },
      sentCount: result.sentCount,
      failureCount: result.failureCount,
      cleanedInvalidTokens: result.invalidTokens.length
    });
  } catch (err) {
    next(err);
  }
};
