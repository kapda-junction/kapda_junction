/**
 * Backfill embeddings for products that have none (existing DB rows).
 * Create/PUT already call embedProduct() when OPENAI_API_KEY is set; use this after imports or old data.
 * Run: npm run backfill-embeddings
 * Re-build all vectors (e.g. after changing buildEmbeddingInput): npm run backfill-embeddings -- --force
 * Needs: MONGODB_URI + OPENAI_API_KEY
 */
require('dotenv').config();
const mongoose = require('mongoose');
const OpenAI = require('openai');
const connectDB = require('../config/database');
const Product = require('../models/Product');
const Category = require('../models/Category');
const { embedProduct } = require('../services/productEmbeddingService');

const BATCH_DELAY_MS = 150;
const force = process.argv.includes('--force');

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  if (!process.env.OPENAI_API_KEY) {
    console.error('OPENAI_API_KEY is required');
    process.exit(1);
  }

  await connectDB();
  const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

  const missingFilter = {
    $or: [
      { embedding: { $exists: false } },
      { embedding: null },
      { embedding: { $size: 0 } }
    ]
  };

  const totalProducts = await Product.countDocuments();
  const needBackfill = await Product.countDocuments(missingFilter);
  console.log(`Products in DB: ${totalProducts}, missing or empty embedding: ${needBackfill}`);

  if (!force && needBackfill === 0) {
    if (totalProducts === 0) {
      console.log('No products in this database — check MONGODB_URI matches where your app reads data.');
    } else {
      console.log('Nothing to backfill: every product already has an embedding.');
      console.log('To refresh all vectors after changing embedding text, run: npm run backfill-embeddings -- --force');
    }
    await mongoose.disconnect();
    process.exit(0);
  }

  const findFilter = force ? {} : missingFilter;
  const candidateCount = force ? totalProducts : needBackfill;
  if (force) {
    console.log(`Force mode: re-embedding all ${candidateCount} products (OpenAI calls + cost).`);
  }

  const cursor = Product.find(findFilter)
    .select('name description category variants price embedding')
    .lean()
    .cursor();

  let updated = 0;
  let skipped = 0;
  let errors = 0;

  for await (const lean of cursor) {
    const name = lean.name;
    const description = lean.description;
    const categoryId = lean.category;
    if (!name || !description || !categoryId) {
      console.warn(`Skip ${lean._id}: missing name, description, or category`);
      skipped++;
      continue;
    }

    try {
      const categoryDoc = await Category.findById(categoryId).select('name').lean();
      if (!categoryDoc) {
        console.warn(`Skip ${lean._id}: category not found`);
        skipped++;
        continue;
      }

      const vector = await embedProduct(
        client,
        { name, description, variants: lean.variants, price: lean.price },
        categoryDoc.name
      );
      if (!vector?.length) {
        console.warn(`Skip ${lean._id}: embedding API returned empty`);
        skipped++;
        continue;
      }

      await Product.updateOne({ _id: lean._id }, { $set: { embedding: vector } });
      updated++;
      console.log(`Embedded ${lean._id} (${name})`);
      await sleep(BATCH_DELAY_MS);
    } catch (e) {
      errors++;
      console.error(`Error on ${lean._id}:`, e.message || e);
    }
  }

  console.log(`Done. Updated: ${updated}, skipped: ${skipped}, errors: ${errors}. (Candidates: ${candidateCount}.)`);
  await mongoose.disconnect();
  process.exit(errors > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
