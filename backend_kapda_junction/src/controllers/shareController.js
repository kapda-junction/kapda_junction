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
  const reqId = req.params.id;
  console.log(`[share] GET /share/product/${reqId}`);
  try {
    const product = await Product.findById(reqId)
      .populate('category', 'name')
      .lean();

    if (!product || !product.isActive) {
      console.log(`[share] product not found or inactive: ${reqId}`);
      return res.status(404).send(`<!DOCTYPE html><html><head><title>Not Found</title></head>
        <body style="font-family:system-ui;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;">
          <p style="color:#64748b;">Product not found.</p>
        </body></html>`);
    }

    console.log(`[share] product found: "${product.name}", images: ${JSON.stringify(product.images)}, isActive: ${product.isActive}`);

    const image    = product.images?.[0] || '';
    const imageUrl = image.startsWith('http') ? image : (image ? `${BASE_URL}${image}` : '');
    console.log(`[share] BASE_URL="${BASE_URL}" | raw image="${image}" | resolved imageUrl="${imageUrl}"`);
    const title    = escapeHtml(product.name);
    const price    = `₹${product.price}`;
    const desc     = escapeHtml((product.description || `${price} - Shop at Kapda Junction`).slice(0, 160));
    const sharePageUrl = `${BASE_URL}/share/product/${product._id}`;
    const appDeepLink     = `kapdajunction:///share/product/${product._id}`;
    const androidIntent   = `intent://share/product/${product._id}#Intent;scheme=kapdajunction;package=com.kadadjunction.flutter_kapda_junction;end`;

    const waMsg = encodeURIComponent(
      `Hi! I'm interested in buying *${product.name}* (${price}). Is it available?\n\n🔗 ${sharePageUrl}`
    );
    const waUrl = `https://wa.me/919770525851?text=${waMsg}`;

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} | Kapda Junction</title>

  <!-- Open Graph — WhatsApp/Facebook rich preview -->
  <meta property="og:type"              content="website">
  <meta property="og:url"               content="${escapeHtml(sharePageUrl)}">
  <meta property="og:title"             content="${title} — ${price}">
  <meta property="og:description"       content="${desc}">
  <meta property="og:site_name"         content="Kapda Junction">
  <meta property="og:locale"            content="en_IN">
  ${imageUrl ? `
  <meta property="og:image"             content="${escapeHtml(imageUrl)}">
  <meta property="og:image:secure_url"  content="${escapeHtml(imageUrl)}">
  <meta property="og:image:type"        content="image/jpeg">
  <meta property="og:image:width"       content="600">
  <meta property="og:image:height"      content="600">
  <meta name="twitter:card"             content="summary_large_image">
  <meta name="twitter:image"            content="${escapeHtml(imageUrl)}">
  ` : `<meta name="twitter:card" content="summary">`}
  <meta name="twitter:title"       content="${title}">
  <meta name="twitter:description" content="${desc}">

  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:system-ui,-apple-system,sans-serif;background:#f1f5f9;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:16px}
    .card{max-width:380px;width:100%;background:#fff;border-radius:20px;overflow:hidden;box-shadow:0 8px 40px rgba(0,0,0,.13)}
    .img-wrap{width:100%;aspect-ratio:1/1;background:#e2e8f0;overflow:hidden;position:relative}
    .img-wrap img{width:100%;height:100%;display:block;object-fit:cover}
    .no-img{display:flex;align-items:center;justify-content:center;width:100%;height:100%;color:#94a3b8;font-size:14px}
    .info{padding:20px}
    .brand{font-size:11px;font-weight:700;letter-spacing:1.2px;color:#f59e0b;text-transform:uppercase;margin-bottom:4px}
    .name{font-size:1.2rem;font-weight:800;color:#0f172a;line-height:1.3;margin-bottom:6px}
    .price{font-size:1.5rem;font-weight:800;color:#0f172a;margin-bottom:20px}
    .redirect-bar{background:#0f172a;color:#fff;text-align:center;padding:12px 16px;font-size:13px;font-weight:600;display:none}
    .redirect-bar.show{display:block}
    .btn{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;padding:14px;color:#fff;text-decoration:none;font-weight:700;font-size:15px;border-radius:12px;cursor:pointer;border:none;margin-bottom:10px}
    .btn-app{background:#0f172a}
    .btn-wa{background:#25D366}
    .btn:last-child{margin-bottom:0}
  </style>
</head>
<body>
  <div class="card">
    <div class="img-wrap">
      ${imageUrl
        ? `<img id="product-img" src="${escapeHtml(imageUrl)}" alt="${title}" loading="eager">`
        : ''
      }
      <div id="img-fallback" class="no-img"${imageUrl ? ' style="display:none"' : ''}>No image</div>
    </div>
    <div id="redirect-bar" class="redirect-bar">Opening Kapda Junction app…</div>
    <div class="info">
      <p class="brand">Kapda Junction</p>
      <h1 class="name">${title}</h1>
      <p class="price">${price}</p>

      <button class="btn btn-app" onclick="openApp()">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <rect x="5" y="2" width="14" height="20" rx="2"/>
          <circle cx="12" cy="17" r="1" fill="white" stroke="none"/>
        </svg>
        Open in Kapda Junction App
      </button>

      <a class="btn btn-wa" href="${escapeHtml(waUrl)}">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="white">
          <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
        </svg>
        Order on WhatsApp
      </a>
    </div>
  </div>

  <script>
    var DEEP_LINK = '${appDeepLink}';

    // Fix broken image without inline onerror
    var productImg = document.getElementById('product-img');
    if (productImg) {
      productImg.addEventListener('error', function() {
        productImg.style.display = 'none';
        document.getElementById('img-fallback').style.display = 'flex';
      });
    }

    function openApp() {
      document.getElementById('redirect-bar').classList.add('show');
      window.location.href = DEEP_LINK;
      // Hide bar after 2s (app launched or not installed)
      setTimeout(function() {
        document.getElementById('redirect-bar').classList.remove('show');
      }, 2000);
    }

    // Auto-attempt on mobile page load (only Android/iOS, not desktop)
    var ua = navigator.userAgent || '';
    var isMobile = /Android|iPhone|iPad|iPod/i.test(ua);
    if (isMobile) {
      setTimeout(openApp, 800);
c    }
  </script>
</body>
</html>`;

    console.log(`[share] serving HTML for "${product.name}" | shareUrl="${sharePageUrl}" | deepLink="${appDeepLink}"`);
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate');
    res.set('Pragma', 'no-cache');
    res.set('Expires', '0');
    res.type('html').send(html);
  } catch (err) {
    console.error(`[share] ERROR for id=${reqId}:`, err);
    next(err);
  }
};
