const express = require('express');
const router = express.Router();
const couponController = require('../controllers/couponController');
const { protect, authorize } = require('../middleware/auth');

router.get('/', protect, authorize('admin'), couponController.list);
router.post('/', protect, authorize('admin'), couponController.create);
router.put('/:id', protect, authorize('admin'), couponController.update);
router.delete('/:id', protect, authorize('admin'), couponController.remove);
router.post('/validate', protect, couponController.validate);

module.exports = router;
