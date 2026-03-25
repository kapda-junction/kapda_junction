const { buildEmbeddingInput } = require('../utils/productEmbedding');

const EMBEDDING_MODEL = 'text-embedding-3-small';

/**
 * @param {import('openai').default} openaiClient
 * @param {{ name?: string; description?: string; variants?: unknown[]; price?: unknown }} productLike
 * @param {string|undefined} categoryName
 * @returns {Promise<number[]|null>}
 */
async function embedProduct(openaiClient, productLike, categoryName) {
  if (!openaiClient || !process.env.OPENAI_API_KEY) return null;
  if (!productLike?.name || !productLike?.description || categoryName == null || categoryName === '') {
    return null;
  }
  const text = buildEmbeddingInput(productLike, categoryName);
  const res = await openaiClient.embeddings.create({
    model: EMBEDDING_MODEL,
    input: text
  });
  return res.data[0].embedding;
}

module.exports = { embedProduct, EMBEDDING_MODEL };
