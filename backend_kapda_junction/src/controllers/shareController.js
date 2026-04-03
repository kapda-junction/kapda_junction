const Product = require('../models/Product');

const BASE_URL = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;

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
    const sharePageUrl = `${BASE_URL}/share/product/${product._id}`;

    const waMsg = encodeURIComponent(`Hi! I'm interested in buying *${product.name}* (₹${product.price}). Is it available?`);
    const waUrl = `https://wa.me/919770525851?text=${waMsg}`;

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} | Kapda Junction</title>
  <!-- Open Graph / WhatsApp rich preview -->
  <meta property="og:type" content="website">
  <meta property="og:url" content="${escapeHtml(sharePageUrl)}">
  <meta property="og:title" content="${title} — ₹${product.price}">
  <meta property="og:description" content="${desc}">
  <meta property="og:image" content="${escapeHtml(imageUrl)}">
  <meta property="og:image:secure_url" content="${escapeHtml(imageUrl)}">
  <meta property="og:image:type" content="image/jpeg">
  <meta property="og:image:width" content="600">
  <meta property="og:image:height" content="600">
  <meta property="og:site_name" content="Kapda Junction">
  <meta property="og:locale" content="en_IN">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${title}">
  <meta name="twitter:description" content="${desc}">
  <meta name="twitter:image" content="${escapeHtml(imageUrl)}">
</head>
<body style="margin:0;font-family:system-ui,-apple-system,sans-serif;background:#f8fafc;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:1rem;">
  <div style="max-width:400px;width:100%;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,0.12);">
    <img src="${escapeHtml(imageUrl)}" alt="${title}" style="width:100%;aspect-ratio:4/5;object-fit:cover;" />
    <div style="padding:1.25rem;">
      <p style="margin:0 0 4px;font-size:11px;font-weight:700;letter-spacing:1px;color:#f59e0b;text-transform:uppercase;">Kapda Junction</p>
      <h1 style="margin:0 0 8px;font-size:1.2rem;font-weight:800;color:#0f172a;line-height:1.3;">${title}</h1>
      <p style="margin:0 0 1.25rem;font-size:1.4rem;font-weight:800;color:#0f172a;">₹${product.price}</p>
      <a href="${escapeHtml(waUrl)}" style="display:flex;align-items:center;justify-content:center;gap:8px;width:100%;padding:14px;background:#25D366;color:#fff;text-align:center;text-decoration:none;font-weight:700;font-size:15px;border-radius:10px;box-sizing:border-box;">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="white"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg>
        Order on WhatsApp
      </a>
    </div>
  </div>
</body>
</html>`;

    res.type('html').send(html);
  } catch (err) {
    next(err);
  }
};
