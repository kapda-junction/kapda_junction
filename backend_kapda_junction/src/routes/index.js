const express = require('express');
const authRoutes = require('./authRoutes');
const categoryRoutes = require('./categoryRoutes');
const productRoutes = require('./productRoutes');
const orderRoutes = require('./orderRoutes');
const colorRoutes = require('./colorRoutes');
const sizeRoutes = require('./sizeRoutes');

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/categories', categoryRoutes);
router.use('/products', productRoutes);
router.use('/orders', orderRoutes);
router.use('/colors', colorRoutes);
router.use('/sizes', sizeRoutes);

router.get('/health', (req, res) => res.json({ status: 'ok', service: 'kapda-junction-api' }));

module.exports = router;
