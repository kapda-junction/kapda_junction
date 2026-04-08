const express = require('express');
const router = express.Router();
const settingController = require('../controllers/settingController');
const { protect, authorize } = require('../middleware/auth');

router.get('/', settingController.getPublic);
router.put('/', protect, authorize('admin'), settingController.updateSettings);

module.exports = router;
