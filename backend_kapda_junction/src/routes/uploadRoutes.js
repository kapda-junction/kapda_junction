const express = require('express');
const router = express.Router();
const uploadController = require('../controllers/uploadController');
const { protect, authorize } = require('../middleware/auth');
const { upload } = require('../middleware/upload');

router.post('/image', protect, authorize('admin'), upload.single('image'), uploadController.uploadImage);
router.post('/banner', protect, authorize('admin'), upload.single('image'), uploadController.uploadBanner);
router.post('/images', protect, authorize('admin'), upload.array('images', 10), uploadController.uploadMultiple);

module.exports = router;
