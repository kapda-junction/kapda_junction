require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const connectDB = require('./config/database');
const errorHandler = require('./middleware/errorHandler');

// Route imports
const productRoutes = require('./routes/productRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const orderRoutes = require('./routes/orderRoutes');
const cartRoutes = require('./routes/cartRoutes');
const authRoutes = require('./routes/authRoutes');
const uploadRoutes = require('./routes/uploadRoutes');
const settingRoutes = require('./routes/settingRoutes');
const colorRoutes = require('./routes/colorRoutes');
const sizeRoutes = require('./routes/sizeRoutes');
const bannerRoutes = require('./routes/bannerRoutes');
const wishlistRoutes = require('./routes/wishlistRoutes');
const activityRoutes = require('./routes/activityRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const shareController = require('./controllers/shareController');

const app = express();

// Middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
  crossOriginEmbedderPolicy: false
}));
const corsOrigins = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(',').map(o => o.trim())
  : ['http://localhost:4200', 'http://localhost:4201'];

app.use(cors({
  origin: corsOrigins,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(morgan('dev'));
// Ensure DB connected (for Vercel serverless).
// Health check should stay lightweight so keep-alive pings don't repeatedly pay DB cost.
app.use(async (req, res, next) => {
  if (req.path === '/api/health') return next();
  try {
    await connectDB();
    next();
  } catch (err) {
    console.error('DB connect error:', err.message);
    res.status(500).json({ message: 'Database connection failed' });
  }
});
// Razorpay webhook MUST use raw body for signature verification - before express.json
app.post('/api/orders/webhook', express.raw({ type: 'application/json' }), require('./controllers/orderController').webhook);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// API Routes
app.use('/api/products', productRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/settings', settingRoutes);
app.use('/api/colors', colorRoutes);
app.use('/api/sizes', sizeRoutes);
app.use('/api/banners', bannerRoutes);
app.use('/api/wishlist', wishlistRoutes);
app.use('/api/activity', activityRoutes);
app.use('/api/admin/notifications', notificationRoutes);

// Health check
app.get('/api/health', (req, res) => res.json({ status: 'ok', timestamp: new Date().toISOString() }));

// Share page - OG meta for WhatsApp/FB link preview, then redirect to frontend
app.get('/share/product/:id', shareController.shareProduct);

app.use(errorHandler);

module.exports = app;
