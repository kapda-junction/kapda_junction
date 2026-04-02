const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { protect, authorize } = require('../middleware/auth');

router.get('/audience', protect, authorize('admin'), notificationController.listAudience);
router.post('/send', protect, authorize('admin'), notificationController.sendNotification);
router.post('/send-user', protect, authorize('admin'), notificationController.sendUserNotification);

module.exports = router;
