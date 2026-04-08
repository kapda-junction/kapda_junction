const multer = require('multer');
const path = require('path');

// Use memoryStorage - no disk needed (Vercel serverless has read-only filesystem)
const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  const allowed = /jpeg|jpg|png|webp|gif|heic|heif|avif/i;
  const ext = path.extname(file.originalname || '').slice(1).toLowerCase();
  const mimetype = (file.mimetype || '').toLowerCase();
  if (allowed.test(ext) || allowed.test(mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only images (jpeg, jpg, png, webp, gif, heic, avif) allowed'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }
});

const videoFileFilter = (req, file, cb) => {
  const mime = (file.mimetype || '').toLowerCase();
  const ext = path.extname(file.originalname || '').slice(1).toLowerCase();
  const ok = /video\/(mp4|quicktime|webm|x-msvideo)/.test(mime) ||
    /mp4|mov|webm|avi|mkv/.test(ext);
  if (ok) cb(null, true);
  else cb(new Error('Only video files (mp4, mov, webm) allowed'), false);
};

const _mb = parseInt(process.env.RETURN_VIDEO_MAX_MB || '20', 10);
const returnVideoMaxBytes = (Number.isFinite(_mb) ? _mb : 20) * 1024 * 1024;

const uploadReturnVideo = multer({
  storage,
  fileFilter: videoFileFilter,
  limits: {
    fileSize: Math.min(Math.max(returnVideoMaxBytes, 5 * 1024 * 1024), 40 * 1024 * 1024)
  }
});

module.exports = { upload, uploadReturnVideo };
