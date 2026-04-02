const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { protect, optionalAuth, authorize } = require('../middleware/auth');

router.get('/', optionalAuth, productController.getAll);
router.get('/landing', optionalAuth, productController.getLanding);
router.get('/featured', productController.getFeatured);
router.get('/suggestions', productController.getSuggestions);
router.get('/:id', optionalAuth, productController.getOne);
router.post('/', protect, authorize('admin'), productController.create);
router.put('/:id', protect, authorize('admin'), productController.update);
router.delete('/:id', protect, authorize('admin'), productController.delete);
router.post('/ai-search', productController.aiSearch);

module.exports = router;
