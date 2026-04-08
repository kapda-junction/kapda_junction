const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { protect, authorize } = require('../middleware/auth');

router.get('/product/:productId', reviewController.listForProduct);
router.post('/', protect, reviewController.create);
router.get('/mine', protect, reviewController.mine);
router.get('/admin', protect, authorize('admin'), reviewController.adminList);
router.put('/admin/:id', protect, authorize('admin'), reviewController.adminUpdate);

module.exports = router;
