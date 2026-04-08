const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { protect, authorize } = require('../middleware/auth');

router.get('/', protect, orderController.getAll);
router.get('/:id', protect, orderController.getOne);
router.post('/', protect, orderController.create);
router.post('/create-payment', protect, orderController.createPayment);
router.post('/verify-payment', protect, orderController.verifyPayment);
router.put('/:id/status', protect, authorize('admin'), orderController.updateStatus);
router.post('/:id/retry-refund', protect, authorize('admin'), orderController.retryRefund);
router.put('/:id/cancel-customer', protect, orderController.cancelOrderCustomer);
router.put('/:id/cancel', protect, authorize('admin'), orderController.cancelOrder);

module.exports = router;
