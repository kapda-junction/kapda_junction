/**
 * Expands storefront ?search= text so regional words (e.g. attar) also hit English catalog copy.
 */
function expandProductSearchTerms(raw) {
  const q = String(raw ?? '').trim();
  if (!q) return [];

  const lower = q.toLowerCase();
  const terms = new Set([q]);

  const attarLike = new Set(['attar', 'ittar', 'itr', 'itra']);
  if (attarLike.has(lower)) {
    ['perfume', 'fragrances', 'fragrance', 'cologne', 'scent', 'body spray', 'eau de', 'parfum'].forEach(
      (t) => terms.add(t)
    );
  }

  if (/^perfumes?$/.test(lower)) {
    ['attar', 'ittar', 'itr', 'fragrance', 'scent', 'cologne'].forEach((t) => terms.add(t));
  }

  return [...terms];
}

module.exports = { expandProductSearchTerms };
