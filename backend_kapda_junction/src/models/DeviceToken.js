const mongoose = require('mongoose');

// Stores FCM tokens for anonymous (non-logged-in) devices.
// When a user logs in from a device, their token moves to User.fcmTokens
// and gets removed from here to avoid sending duplicates.
const deviceTokenSchema = new mongoose.Schema({
  deviceId: { type: String, required: true, unique: true },
  token:    { type: String, required: true, unique: true },
  platform: { type: String, enum: ['android', 'ios', 'web'], default: 'android' },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('DeviceToken', deviceTokenSchema);
