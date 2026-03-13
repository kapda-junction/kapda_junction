const express = require('express');
const router = express.Router();
const bannerController = require('../controllers/bannerController');
const { protect, authorize } = require('../middleware/auth');

router.get('/', protect, authorize('admin'), bannerController.getAll);
router.get('/active', bannerController.getActive);
router.post('/', protect, authorize('admin'), bannerController.create);
router.put('/:id', protect, authorize('admin'), bannerController.update);
router.delete('/:id', protect, authorize('admin'), bannerController.delete);

module.exports = router;
