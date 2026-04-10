const express = require('express');
const router = express.Router();
const wishlistController = require('../controllers/wishlistController');
const { protect } = require('../middleware/auth');

router.get('/', protect, wishlistController.getWishlist);
router.get('/ids', protect, wishlistController.getWishlistIds);
router.delete('/', protect, wishlistController.clearWishlist);
router.post('/:productId', protect, wishlistController.addToWishlist);
router.delete('/:productId', protect, wishlistController.removeFromWishlist);

module.exports = router;
