const multer = require('multer');
const path = require('path');
const fs = require('fs');

const UPLOAD_DIR = path.join(process.cwd(), 'tmp_uploads');
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

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

module.exports = { upload };
