/**
 * Text used for OpenAI embeddings — keep in sync across create / update / backfill.
 */
function perfumeRelatedAliasBlock(categoryName, name, description) {
  const blob = `${categoryName ?? ''} ${name ?? ''} ${description ?? ''}`;
  if (
    /perfume|fragrance|cologne|scent|eau de|body spray|parfum|\battar\b|\bittar\b|\bout\b|musk/i.test(blob)
  ) {
    return `

Also known as / searched as: attar, ittar, itr, itra, perfume, fragrance, cologne, scent, oud.
`;
  }
  return '';
}

function buildEmbeddingInput({ name, description, variants, price }, categoryName) {
  const safeName = name ?? '';
  const safeDesc = description ?? '';
  const colors = Array.isArray(variants) ? variants.map((v) => v?.color).filter(Boolean).join(', ') : '';
  const cat = categoryName ?? '';
  const p = price ?? '';
  const aliases = perfumeRelatedAliasBlock(cat, safeName, safeDesc);
  return `
${safeName} is a ${safeDesc}.
Category: ${cat}.
Available colors: ${colors}.
Price: ${p}${aliases}
`;
}

module.exports = { buildEmbeddingInput };
