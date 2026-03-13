const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { protect, authorize } = require('../middleware/auth');

router.get('/', protect, orderController.getAll);
router.get('/:id', protect, orderController.getOne);
router.post('/', protect, orderController.create);
router.put('/:id/status', protect, authorize('admin'), orderController.updateStatus);

module.exports = router;
