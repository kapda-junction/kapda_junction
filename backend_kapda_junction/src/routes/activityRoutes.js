const express = require('express');
const router = express.Router();
const activityController = require('../controllers/activityController');
const { protect, optionalAuth } = require('../middleware/auth');

router.post('/search', optionalAuth, activityController.trackSearch);
router.post('/view', optionalAuth, activityController.trackView);
router.get('/searches', protect, activityController.getRecentSearches);
router.get('/views', protect, activityController.getRecentViews);

module.exports = router;
