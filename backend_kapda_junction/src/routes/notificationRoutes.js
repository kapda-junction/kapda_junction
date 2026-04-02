const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { protect, authorize } = require('../middleware/auth');

router.post('/send-user', protect, authorize('admin'), notificationController.sendUserNotification);

module.exports = router;
