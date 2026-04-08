const rateLimit = require('express-rate-limit');

/**
 * Per-IP limit for return proof uploads (Cloudinary cost control).
 * RETURN_VIDEO_UPLOAD_MAX (default 20) requests per RETURN_VIDEO_UPLOAD_WINDOW_MS (default 1h).
 * Set RETURN_VIDEO_UPLOAD_MAX=0 to disable (not recommended for production).
 */
function returnVideoUploadLimiter() {
  const max = parseInt(process.env.RETURN_VIDEO_UPLOAD_MAX || '20', 10);
  const windowMs = parseInt(process.env.RETURN_VIDEO_UPLOAD_WINDOW_MS || `${60 * 60 * 1000}`, 10);
  if (!Number.isFinite(max) || max <= 0) {
    return (req, res, next) => next();
  }
  return rateLimit({
    windowMs: Number.isFinite(windowMs) && windowMs > 0 ? windowMs : 3600000,
    max,
    standardHeaders: true,
    legacyHeaders: false,
    message: { message: 'Too many return video uploads. Try again later.' }
  });
}

module.exports = { returnVideoUploadLimiter };
