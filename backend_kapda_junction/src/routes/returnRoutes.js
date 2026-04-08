const express = require('express');
const router = express.Router();
const returnController = require('../controllers/returnController');
const { protect, authorize } = require('../middleware/auth');

router.get('/', protect, returnController.list);
router.post('/', protect, returnController.create);
router.get('/:id', protect, returnController.getOne);
router.put('/:id/cancel', protect, returnController.cancelMine);
router.put('/:id', protect, authorize('admin'), returnController.update);

module.exports = router;
