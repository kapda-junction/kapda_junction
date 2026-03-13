const Product = require('../models/Product');

const BASE_URL = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
const FRONTEND_URL = process.env.FRONTEND_URL || 'http://localhost:4200';

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

exports.shareProduct = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.id)
      .populate('category', 'name')
      .lean();
    if (!product) {
      return res.status(404).send(`
        <!DOCTYPE html>
        <html><head><title>Product Not Found</title></head>
        <body><h1>Product not found</h1></body></html>
      `);
    }
    if (!product.isActive) {
      return res.status(404).send(`
        <!DOCTYPE html>
        <html><head><title>Product Not Found</title></head>
        <body><h1>Product not found</h1></body></html>
      `);
    }

    const image = product.images?.[0] || 'https://via.placeholder.com/400';
    const imageUrl = image.startsWith('http') ? image : `${BASE_URL}${image}`;
    const title = escapeHtml(product.name);
    const desc = escapeHtml((product.description || `₹${product.price} - Shop at Kapda Junction`).slice(0, 160));
    const productUrl = `${FRONTEND_URL}/products/${product._id}`;
    const sharePageUrl = `${BASE_URL}/share/product/${product._id}`;

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} | Kapda Junction</title>
  <!-- Open Graph / Facebook / WhatsApp -->
  <meta property="og:type" content="website">
  <meta property="og:url" content="${escapeHtml(sharePageUrl)}">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${desc}">
  <meta property="og:image" content="${escapeHtml(imageUrl)}">
  <meta property="og:image:secure_url" content="${escapeHtml(imageUrl)}">
  <meta property="og:image:type" content="image/jpeg">
  <meta property="og:image:width" content="600">
  <meta property="og:image:height" content="600">
  <meta property="og:site_name" content="Kapda Junction">
  <meta property="og:locale" content="en_IN">
  <!-- Twitter -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${title}">
  <meta name="twitter:description" content="${desc}">
  <meta name="twitter:image" content="${escapeHtml(imageUrl)}">
</head>
<body style="margin:0;font-family:system-ui,-apple-system,sans-serif;background:#f8fafc;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:1rem;">
  <div style="max-width:420px;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,0.1);">
    <img src="${escapeHtml(imageUrl)}" alt="${title}" style="width:100%;aspect-ratio:1;object-fit:cover;" />
    <div style="padding:1.25rem;">
      <h1 style="margin:0 0 0.5rem;font-size:1.25rem;color:#0f172a;">${title}</h1>
      <p style="margin:0 0 1rem;font-size:1.25rem;font-weight:700;color:#0f172a;">₹${product.price}</p>
      <a href="${escapeHtml(productUrl)}" style="display:block;width:100%;padding:0.875rem 1.5rem;background:#0f172a;color:#fff;text-align:center;text-decoration:none;font-weight:600;border-radius:8px;">Visit &amp; Buy →</a>
    </div>
  </div>
  <meta http-equiv="refresh" content="2;url=${escapeHtml(productUrl)}">
  <script>setTimeout(function(){ window.location.href = "${String(productUrl).replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"; }, 800);</script>
</body>
</html>`;

    res.type('html').send(html);
  } catch (err) {
    next(err);
  }
};
