const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { protect } = require('../middleware/auth');

router.post('/register', authController.register);
router.post('/login', authController.login);
router.get('/me', protect, authController.getMe);
router.post('/fcm-token', protect, authController.saveFcmToken);
router.get('/addresses', protect, authController.getAddresses);
router.post('/addresses', protect, authController.addAddress);
router.put('/addresses/:id', protect, authController.updateAddress);
router.delete('/addresses/:id', protect, authController.deleteAddress);
router.patch('/addresses/:id/default', protect, authController.setDefaultAddress);

module.exports = router;
