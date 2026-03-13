const express = require('express');
const router = express.Router();
const colorController = require('../controllers/colorController');
const { protect, authorize } = require('../middleware/auth');

router.get('/', protect, colorController.getAll);
router.get('/:id', protect, colorController.getOne);
router.post('/', protect, authorize('admin'), colorController.create);
router.put('/:id', protect, authorize('admin'), colorController.update);
router.delete('/:id', protect, authorize('admin'), colorController.delete);

module.exports = router;
