const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/categoryController');
const { protect, optionalAuth, authorize } = require('../middleware/auth');

router.get('/', optionalAuth, categoryController.getAll);
router.get('/tree', optionalAuth, categoryController.getTree);
router.get('/:id', categoryController.getOne);
router.post('/', protect, authorize('admin'), categoryController.create);
router.put('/:id', protect, authorize('admin'), categoryController.update);
router.delete('/:id', protect, authorize('admin'), categoryController.delete);

module.exports = router;
