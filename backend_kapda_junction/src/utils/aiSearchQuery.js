/**
 * RAG helper: parse budget + semantic text for aiSearch (query → embedding → vector search).
 */

function parseNum(str) {
  const n = parseFloat(String(str).replace(/,/g, ''));
  return Number.isFinite(n) ? n : undefined;
}

function applyKMultiplier(n, fragment) {
  if (n == null) return undefined;
  if (/\d\s*k\b/i.test(fragment) || /\d+k\b/i.test(fragment)) return n * 1000;
  if (/thousand/i.test(fragment)) return n * 1000;
  return n;
}

const MAX_PRICE_RE =
  /(?:under|below|less\s+than|at\s+most|max(?:imum)?|upto|up\s+to|within)\s*(?:rs\.?|₹|inr)?\s*(\d[\d,]*(?:\.\d+)?)(?:\s*k|\s*thousand)?\b/gi;

const MIN_PRICE_RE =
  /(?:above|over|more\s+than|at\s+least|min(?:imum)?)\s*(?:rs\.?|₹|inr)?\s*(\d[\d,]*(?:\.\d+)?)(?:\s*k|\s*thousand)?\b/gi;

const STRIP_MAX_RE =
  /(?:under|below|less\s+than|at\s+most|max(?:imum)?|upto|up\s+to|within)\s*(?:rs\.?|₹|inr)?\s*\d[\d,]*(?:\.\d+)?(?:\s*k|\s*thousand)?\b/gi;

const STRIP_MIN_RE =
  /(?:above|over|more\s+than|at\s+least|min(?:imum)?)\s*(?:rs\.?|₹|inr)?\s*\d[\d,]*(?:\.\d+)?(?:\s*k|\s*thousand)?\b/gi;

/** When the query is only a budget (no product words), list search skips text $or and filters by price only. */
const LIST_SEARCH_SEMANTIC_FALLBACK = 'menswear clothing fashion';

const TYPO_FIXES = [
  [/\bjens\b/gi, 'jeans'],
  [/\bjean\b/gi, 'jeans'],
  [/\bshrt\b/gi, 'shirt'],
  [/\bt\s*shirt\b/gi, 'tshirt'],
  [/\btring\b/gi, 't shirt']
];

function normalizeTypos(s) {
  let out = s;
  for (const [re, rep] of TYPO_FIXES) {
    out = out.replace(re, rep);
  }
  return out;
}

function parseNaturalProductQuery(raw) {
  const original = String(raw ?? '').trim();
  if (!original) {
    return { semanticQuery: '', maxPrice: undefined, minPrice: undefined, original: '' };
  }

  let maxPrice;
  let minPrice;
  let m;

  MAX_PRICE_RE.lastIndex = 0;
  while ((m = MAX_PRICE_RE.exec(original)) !== null) {
    const n = applyKMultiplier(parseNum(m[1]), m[0]);
    if (n != null) maxPrice = maxPrice == null ? n : Math.min(maxPrice, n);
  }

  MIN_PRICE_RE.lastIndex = 0;
  while ((m = MIN_PRICE_RE.exec(original)) !== null) {
    const n = applyKMultiplier(parseNum(m[1]), m[0]);
    if (n != null) minPrice = minPrice == null ? n : Math.max(minPrice, n);
  }

  let semantic = original
    .replace(STRIP_MAX_RE, ' ')
    .replace(STRIP_MIN_RE, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  semantic = normalizeTypos(semantic);
  if (!semantic) semantic = LIST_SEARCH_SEMANTIC_FALLBACK;

  return {
    semanticQuery: semantic,
    maxPrice,
    minPrice,
    original
  };
}

function priceMongoFilter({ maxPrice, minPrice }) {
  const f = {};
  if (maxPrice != null) f.$lte = maxPrice;
  if (minPrice != null) f.$gte = minPrice;
  return Object.keys(f).length ? { price: f } : {};
}

function filterProductsByBudget(products, { maxPrice, minPrice }) {
  return products.filter((p) => {
    const price = p.price;
    if (typeof price !== 'number') return true;
    if (maxPrice != null && price > maxPrice) return false;
    if (minPrice != null && price < minPrice) return false;
    return true;
  });
}

function vectorSearchFilter(parsed) {
  const base = { isActive: true };
  const pricePart = priceMongoFilter({
    maxPrice: parsed.maxPrice,
    minPrice: parsed.minPrice
  });
  if (pricePart.price) {
    Object.assign(base, pricePart);
  }
  return base;
}

module.exports = {
  parseNaturalProductQuery,
  priceMongoFilter,
  filterProductsByBudget,
  normalizeTypos,
  vectorSearchFilter,
  LIST_SEARCH_SEMANTIC_FALLBACK
};
