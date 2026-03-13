const express = require('express');
const router = express.Router();
const sizeController = require('../controllers/sizeController');
const { protect, authorize } = require('../middleware/auth');

router.get('/', protect, sizeController.getAll);
router.get('/:id', protect, sizeController.getOne);
router.post('/', protect, authorize('admin'), sizeController.create);
router.put('/:id', protect, authorize('admin'), sizeController.update);
router.delete('/:id', protect, authorize('admin'), sizeController.delete);

module.exports = router;
