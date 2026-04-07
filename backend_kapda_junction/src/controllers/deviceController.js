const DeviceToken = require('../models/DeviceToken');

// Public endpoint — no auth required.
// Registers (or updates) the FCM token for an anonymous device.
// When the user later logs in, authController.saveFcmToken moves the token
// to User.fcmTokens and removes it from this collection.
exports.registerDeviceToken = async (req, res, next) => {
  try {
    const { deviceId, token, platform } = req.body;
    if (!deviceId || !token) {
      return res.status(400).json({ message: 'deviceId and token are required' });
    }

    // If the same FCM token was registered under a different deviceId
    // (shouldn't happen, but guard against it to keep token unique)
    await DeviceToken.deleteMany({ token, deviceId: { $ne: deviceId } });

    await DeviceToken.findOneAndUpdate(
      { deviceId },
      { token, platform: platform || 'android', updatedAt: new Date() },
      { upsert: true, new: true }
    );

    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
};
