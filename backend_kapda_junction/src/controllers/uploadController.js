const sharp = require('sharp');
const cloudinary = require('../config/cloudinary');
const { Readable } = require('stream');

// heic-convert has native deps - optional on Vercel serverless
let heicConvert = null;
try {
  heicConvert = require('heic-convert');
} catch (e) {
  console.warn('heic-convert not available (HEIC uploads disabled on this platform)');
}

const isHeic = (file) => {
  const ext = (file.originalname || '').toLowerCase().split('.').pop();
  const mime = (file.mimetype || '').toLowerCase();
  return /heic|heif/i.test(ext) || /heic|heif/i.test(mime);
};

const streamToBuffer = (stream) =>
  new Promise((resolve, reject) => {
    const chunks = [];
    stream.on('data', (chunk) => chunks.push(chunk));
    stream.on('end', () => resolve(Buffer.concat(chunks)));
    stream.on('error', reject);
  });
const bufferToStream = (buf) => {
  const readable = new Readable();
  readable._read = () => {};
  readable.push(buf);
  readable.push(null);
  return readable;
};

/** Hard cap for product gallery images after server-side compression (~100 KiB). */
const MAX_PRODUCT_IMAGE_BYTES = 100 * 1024;

/**
 * Resize + JPEG encode, then lower quality / dimensions until size <= maxBytes (best effort).
 */
async function compressProductJpegUnderMax(inputBuffer, maxBytes = MAX_PRODUCT_IMAGE_BYTES) {
  let maxSide = 1200;
  let quality = 78;
  const minSide = 320;
  const minQuality = 26;
  const maxAttempts = 48;

  const encode = () =>
    sharp(inputBuffer)
      .rotate()
      .resize(maxSide, maxSide, { fit: 'inside', withoutEnlargement: true })
      .jpeg({
        quality,
        mozjpeg: true,
        chromaSubsampling: '4:2:0'
      })
      .toBuffer();

  let out = await encode();
  let attempts = 0;

  while (out.length > maxBytes && attempts < maxAttempts) {
    attempts += 1;
    if (quality > minQuality + 5) {
      quality -= 6;
    } else if (maxSide > minSide) {
      maxSide = Math.max(minSide, Math.floor(maxSide * 0.8));
      quality = Math.min(72, quality + 3);
    } else {
      quality = Math.max(minQuality - 2, quality - 3);
      maxSide = Math.max(260, Math.floor(maxSide * 0.92));
    }
    out = await encode();
  }

  if (out.length > maxBytes) {
    out = await sharp(inputBuffer)
      .rotate()
      .resize(240, 240, { fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 24, mozjpeg: true, chromaSubsampling: '4:2:0' })
      .toBuffer();
  }

  return out;
}

/** Product images: no extra Cloudinary transform so byte cap stays predictable. */
const uploadProductToCloudinary = (buffer) => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder: 'kapda_junction/products',
        resource_type: 'image'
      },
      (err, result) => {
        if (err) reject(err);
        else resolve(result.secure_url);
      }
    );
    bufferToStream(buffer).pipe(uploadStream);
  });
};

const uploadToCloudinary = (buffer, folder = 'kapda_junction') => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: 'image',
        transformation: [{ quality: 'auto:good' }]
      },
      (err, result) => {
        if (err) reject(err);
        else resolve(result.secure_url);
      }
    );
    bufferToStream(buffer).pipe(uploadStream);
  });
};

exports.uploadImage = async (req, res, next) => {
  try {
    if (!req.file || !req.file.buffer) {
      return res.status(400).json({ message: 'No image file provided' });
    }
    let buffer = req.file.buffer;
    if (isHeic(req.file)) {
      if (!heicConvert) {
        return res.status(400).json({ message: 'HEIC not supported. Use JPEG, PNG, or WebP.' });
      }
      buffer = await heicConvert({ buffer: req.file.buffer, format: 'JPEG' });
    }
    const compressed = await compressProductJpegUnderMax(buffer);
    const url = await uploadProductToCloudinary(compressed);
    res.json({ url });
  } catch (err) {
    next(err);
  }
};

exports.uploadBanner = async (req, res, next) => {
  try {
    if (!req.file || !req.file.buffer) {
      return res.status(400).json({ message: 'No image file provided' });
    }
    let buffer = req.file.buffer;
    if (isHeic(req.file)) {
      if (!heicConvert) {
        return res.status(400).json({ message: 'HEIC not supported. Use JPEG, PNG, or WebP.' });
      }
      buffer = await heicConvert({ buffer: req.file.buffer, format: 'JPEG' });
    }
    const compressed = await sharp(buffer)
      .resize(1920, 1080, { fit: 'cover', position: 'center' })
      .jpeg({ quality: 85 })
      .toBuffer();
    const url = await uploadToCloudinary(compressed, 'kapda_junction/banners');
    res.json({ url });
  } catch (err) {
    next(err);
  }
};

const uploadVideoToCloudinary = (buffer) => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder: 'kapda_junction/returns',
        resource_type: 'video'
      },
      (err, result) => {
        if (err) reject(err);
        else resolve(result.secure_url);
      }
    );
    bufferToStream(buffer).pipe(uploadStream);
  });
};

/** Customer or admin — short proof video for returns. */
exports.uploadReturnVideo = async (req, res, next) => {
  try {
    if (!req.file?.buffer) {
      return res.status(400).json({ message: 'No video file provided' });
    }
    const url = await uploadVideoToCloudinary(req.file.buffer);
    res.json({ url });
  } catch (err) {
    next(err);
  }
};

exports.uploadMultiple = async (req, res, next) => {
  try {
    const files = req.files || [];
    if (files.length === 0) {
      return res.status(400).json({ message: 'No images provided' });
    }
    const urls = [];
    for (const f of files) {
      let buffer = f.buffer;
      if (isHeic(f)) {
        if (!heicConvert) {
          return res.status(400).json({ message: 'HEIC not supported on this server. Use JPEG, PNG, or WebP.' });
        }
        buffer = await heicConvert({ buffer: f.buffer, format: 'JPEG' });
      }
      const compressed = await compressProductJpegUnderMax(buffer);
      const url = await uploadProductToCloudinary(compressed);
      urls.push(url);
    }
    res.json({ urls });
  } catch (err) {
    next(err);
  }
};
