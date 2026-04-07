const express = require('express');
const router = express.Router();
const { registerDeviceToken } = require('../controllers/deviceController');

// Public — no auth required
router.post('/register-token', registerDeviceToken);

module.exports = router;
