/**
 * Manual carriers (India Post, etc.) — no Shiprocket. Admin enters AWB/article number.
 * Optional full URL override when India Post query format changes.
 * Env: INDIA_POST_TRACK_URL_TEMPLATE — use `{awb}` placeholder, e.g. https://host/track?n={awb}
 */

const FALLBACK_TEMPLATE =
  'https://www.indiapost.gov.in/VAS/Pages/trackconsignment.aspx?consignmentNumber={awb}';

/**
 * @param {string} [carrier] e.g. "India Post"
 * @param {string} [awb] article / consignment number
 * @param {string} [urlOverride] admin-pasted full tracking URL (highest priority)
 * @returns {string|null}
 */
function buildPublicTrackingUrl(carrier, awb, urlOverride) {
  const o = String(urlOverride || '').trim();
  if (o.startsWith('http')) return o;

  const a = String(awb || '').trim();
  if (!a) return null;

  const c = String(carrier || 'India Post').toLowerCase();
  if (c.includes('india post') || c === 'indiapost' || c === 'speed post') {
    const template = process.env.INDIA_POST_TRACK_URL_TEMPLATE || FALLBACK_TEMPLATE;
    if (template.includes('{awb}')) {
      return template.split('{awb}').join(encodeURIComponent(a));
    }
    const sep = template.includes('?') ? '&' : '?';
    return `${template}${sep}consignmentNumber=${encodeURIComponent(a)}`;
  }

  return null;
}

module.exports = { buildPublicTrackingUrl, FALLBACK_TEMPLATE };
