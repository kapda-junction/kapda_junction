const Product = require('../models/Product');
const Category = require('../models/Category');
const OpenAI = require("openai");
const { embedProduct } = require('../services/productEmbeddingService');
const { expandProductSearchTerms } = require('../utils/searchQueryExpand');
const {
  parseNaturalProductQuery,
  priceMongoFilter,
  filterProductsByBudget,
  vectorSearchFilter,
  LIST_SEARCH_SEMANTIC_FALLBACK
} = require('../utils/aiSearchQuery');

const AI_RETRIEVAL_LIMIT = 24;
const AI_NUM_CANDIDATES = 200;
const AI_VECTOR_LIMIT_WIDE = 40;

const escapeRegex = (s) => String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

const buildQuery = (query, isAdmin) => {
  const q = {};
  if (!isAdmin) q.isActive = true;
  if (query.category) q.category = query.category;
  if (query.subcategory) q.subcategory = query.subcategory;
  if (query.search) {
    const parsed = parseNaturalProductQuery(query.search);
    const budgetFromSearch = priceMongoFilter({
      maxPrice: parsed.maxPrice,
      minPrice: parsed.minPrice
    });
    Object.assign(q, budgetFromSearch);

    const hasBudget =
      parsed.maxPrice != null ||
      parsed.minPrice != null;
    const budgetOnly =
      parsed.semanticQuery === LIST_SEARCH_SEMANTIC_FALLBACK && hasBudget;

    if (!budgetOnly) {
      let terms = expandProductSearchTerms(parsed.semanticQuery);
      if (!terms.length) terms = [parsed.semanticQuery];
      q.$or = terms.flatMap((term) => {
        const rx = new RegExp(escapeRegex(term), 'i');
        return [{ name: rx }, { description: rx }];
      });
    }
  }

  if (query.minPrice !== undefined && query.minPrice !== null && String(query.minPrice).trim() !== '') {
    const n = Number(query.minPrice);
    if (Number.isFinite(n)) {
      q.price = q.price || {};
      q.price.$gte = q.price.$gte != null ? Math.max(q.price.$gte, n) : n;
    }
  }
  if (query.maxPrice !== undefined && query.maxPrice !== null && String(query.maxPrice).trim() !== '') {
    const n = Number(query.maxPrice);
    if (Number.isFinite(n)) {
      q.price = q.price || {};
      q.price.$lte = q.price.$lte != null ? Math.min(q.price.$lte, n) : n;
    }
  }
  if (query.soldOut === 'true') q.soldOut = true;
  if (query.soldOut === 'false') q.soldOut = false;
  return q;
};

exports.getFeatured = async (req, res, next) => {
  try {
    const products = await Product.find({ isActive: true, isFeatured: true })
      .populate('category', 'name slug')
      .populate('subcategory', 'name slug')
      .sort('heroOrder -createdAt')
      .limit(10)
      .lean();
    res.json({ products });
  } catch (err) {
    next(err);
  }
};

exports.getLanding = async (req, res, next) => {
  try {
    const isAdmin = req.user?.role === 'admin';
    const limitPerCategory = parseInt(req.query.limit) || 8;
    const productFilter = isAdmin ? {} : { isActive: true };

    const parentCats = await Category.find(isAdmin ? { parent: null } : { isActive: true, parent: null })
      .sort('sortOrder name')
      .lean();

    if (parentCats.length === 0) return res.json({ sections: [] });

    const parentIds = parentCats.map((c) => c._id);
    const subCats = await Category.find({ parent: { $in: parentIds } }).select('parent _id').lean();
    const subIdsByParent = {};
    for (const s of subCats) {
      if (!subIdsByParent[s.parent]) subIdsByParent[s.parent] = [];
      subIdsByParent[s.parent].push(s._id);
    }

    const categoryIdsList = parentCats.map((cat) => [cat._id, ...(subIdsByParent[cat._id] || [])]);

    const sectionPromises = parentCats.map(async (cat, i) => {
      const categoryIds = categoryIdsList[i];
      const filter = { category: { $in: categoryIds }, ...productFilter };
      const [products, total] = await Promise.all([
        Product.find(filter)
          .select('name price images category subcategory soldOut variants')
          .populate('category', 'name slug')
          .populate('subcategory', 'name slug')
          .limit(limitPerCategory)
          .sort('-createdAt')
          .lean(),
        Product.countDocuments(filter)
      ]);
      return { category: cat, products, total };
    });

    const results = await Promise.all(sectionPromises);
    const sections = results.filter((s) => s.products.length > 0 || s.total > 0);
    res.json({ sections });
  } catch (err) {
    next(err);
  }
};

exports.getAll = async (req, res, next) => {
  try {
    const isAdmin = req.user?.role === 'admin';
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 12;
    const skip = (page - 1) * limit;
    let filter = buildQuery(req.query, isAdmin);
    if (req.query.category) {
      const subIds = (await Category.find({ parent: req.query.category }).select('_id').lean()).map((c) => c._id);
      const categoryIds = [req.query.category, ...subIds];
      filter = { ...filter, category: { $in: categoryIds } };
    }
    const [products, total] = await Promise.all([
      Product.find(filter)
        .select('-embedding')
        .populate('category', 'name slug')
        .populate('subcategory', 'name slug')
        .skip(skip)
        .limit(limit)
        .sort('-createdAt'),
      Product.countDocuments(filter)
    ]);
    res.json({ products, total, page, totalPages: Math.ceil(total / limit) });
  } catch (err) {
    next(err);
  }
};

exports.getOne = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.id)
      .select('-embedding')
      .populate('category', 'name slug')
      .populate('subcategory', 'name slug');
    if (!product) return res.status(404).json({ message: 'Product not found' });
    const isAdmin = req.user?.role === 'admin';
    if (!isAdmin && !product.isActive) {
      return res.status(404).json({ message: 'Product not found' });
    }
    res.json(product);
  } catch (err) {
    next(err);
  }
};

// exports.create = async (req, res, next) => {
//   try {
//     const product = await Product.create(req.body);
//     res.status(201).json(product);
//   } catch (err) {
//     next(err);
//   }
// };

exports.create = async (req, res, next) => {
  try {
    const { name, description, category, variants, price } = req.body;

    // 1. Validate
    if (!name || !description || !category) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    // 2. Fetch category name
    const categoryDoc = await Category.findById(category);
    if (!categoryDoc) {
      return res.status(404).json({ message: "Category not found" });
    }

    const vector = await embedProduct(client, { name, description, variants, price }, categoryDoc.name);

    const product = await Product.create({
      ...req.body,
      ...(Array.isArray(vector) && vector.length > 0 ? { embedding: vector } : {})
    });

    // 7. Response
    res.status(201).json(product);

  } catch (err) {
    console.error(err);
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });

    const affectsEmbedding = ['name', 'description', 'category', 'variants', 'price'].some(
      (k) => Object.prototype.hasOwnProperty.call(req.body, k)
    );

    Object.assign(product, req.body);

    const missingEmbedding = !Array.isArray(product.embedding) || product.embedding.length === 0;
    const shouldEmbed = process.env.OPENAI_API_KEY && (affectsEmbedding || missingEmbedding);

    if (shouldEmbed) {
      const categoryDoc = await Category.findById(product.category);
      if (categoryDoc) {
        const vector = await embedProduct(client, product.toObject(), categoryDoc.name);
        if (vector) product.embedding = vector;
      }
    }

    await product.save();
    const updated = await Product.findById(product._id)
      .populate('category', 'name slug')
      .populate('subcategory', 'name slug');
    res.json(updated);
  } catch (err) {
    next(err);
  }
};

exports.delete = async (req, res, next) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.json({ message: 'Product deleted' });
  } catch (err) {
    next(err);
  }
};



async function textSearchProductsForAi(semanticQuery, limit, budget = {}) {
  const q = String(semanticQuery ?? '').trim();
  let terms = expandProductSearchTerms(q);
  if (!terms.length) terms = [q];

  const ors = terms.flatMap((term) => {
    const rx = new RegExp(escapeRegex(term), 'i');
    return [{ name: rx }, { description: rx }];
  });

  const filter = {
    isActive: true,
    ...priceMongoFilter(budget),
    $or: ors
  };

  return Product.find(filter)
    .select('-embedding')
    .sort({ price: 1 })
    .limit(limit)
    .populate('category', 'name slug')
    .populate('subcategory', 'name slug')
    .lean();
}

async function runAiVectorSearch(queryVector, filter, limit, numCandidates) {
  return Product.aggregate([
    {
      $vectorSearch: {
        index: "product_embedding_index",
        path: "embedding",
        queryVector,
        numCandidates,
        limit,
        filter
      }
    },
    {
      $lookup: {
        from: "categories",
        localField: "category",
        foreignField: "_id",
        as: "categoryData"
      }
    },
    { $unwind: { path: "$categoryData", preserveNullAndEmptyArrays: true } }
  ]);
}

exports.aiSearch = async (req, res, next) => {
  try {
    const { query } = req.body;

    if (!query || !String(query).trim()) {
      return res.status(400).json({ message: "Query is required" });
    }

    const q = String(query).trim();
    const parsed = parseNaturalProductQuery(q);
    const budget = { maxPrice: parsed.maxPrice, minPrice: parsed.minPrice };
    const embedInput = (parsed.semanticQuery || q).trim() || q;

    let results = [];
    let usedVector = false;

    const budgetHint =
      parsed.maxPrice != null || parsed.minPrice != null
        ? `\nParsed budget (INR): ${parsed.minPrice != null ? `min ${parsed.minPrice}` : ""}${
            parsed.minPrice != null && parsed.maxPrice != null ? ", " : ""
          }${parsed.maxPrice != null ? `max ${parsed.maxPrice}` : ""}`
        : "";

    if (process.env.OPENAI_API_KEY) {
      try {
        const embeddingRes = await client.embeddings.create({
          model: "text-embedding-3-small",
          input: embedInput
        });
        const queryVector = embeddingRes.data[0].embedding;

        const strictFilter = vectorSearchFilter(parsed);
        let agg = await runAiVectorSearch(
          queryVector,
          strictFilter,
          AI_RETRIEVAL_LIMIT,
          AI_NUM_CANDIDATES
        );
        results = filterProductsByBudget(agg, budget);

        if (!results.length && (parsed.maxPrice != null || parsed.minPrice != null)) {
          agg = await runAiVectorSearch(
            queryVector,
            { isActive: true },
            AI_VECTOR_LIMIT_WIDE,
            AI_NUM_CANDIDATES + 80
          );
          results = filterProductsByBudget(agg, budget).slice(0, AI_RETRIEVAL_LIMIT);
        }

        if (results.length) usedVector = true;
      } catch (vectorErr) {
        console.warn("Vector search unavailable, using text fallback:", vectorErr.message || vectorErr);
      }
    }

    if (!results.length) {
      results = await textSearchProductsForAi(parsed.semanticQuery, AI_RETRIEVAL_LIMIT, budget);
    }
    if (!results.length && (parsed.maxPrice != null || parsed.minPrice != null)) {
      results = await textSearchProductsForAi(parsed.semanticQuery, AI_RETRIEVAL_LIMIT, {});
      results = filterProductsByBudget(results, budget).slice(0, AI_RETRIEVAL_LIMIT);
    }

    results = filterProductsByBudget(results, budget);

    const context = results
      .map((p) => {
        const cname = p.categoryData?.name ?? p.category?.name ?? '';
        return `id: ${p._id}
Name: ${p.name}
Category: ${cname}
Description: ${p.description}
Price (INR): ${p.price}`;
      })
      .join("\n---\n");

    let answer = '';
    if (process.env.OPENAI_API_KEY && context.trim()) {
      const response = await client.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: `You are a helpful men's fashion shopping assistant (RAG).
Rules:
- Only recommend or discuss products that appear in the "Catalog" list below. Never invent items or prices.
- If the user gave a budget (max/min price in INR), only suggest products whose Price (INR) satisfies it. If none qualify, say clearly that nothing in the list matches and suggest broadening the search.
- Prefer the most relevant items to the user's words (e.g. jeans, shirt, perfume).
- Keep answers concise and friendly; mention product names and prices from the list when you recommend something.`
          },
          {
            role: "user",
            content: `Original user message: ${q}
Semantic search focus: ${embedInput}${budgetHint}

Catalog (only valid products):
${context}

Answer the user: what fits their request from this catalog only?`
          }
        ]
      });
      answer = response.choices[0].message.content;
    } else if (!results.length) {
      answer = 'No matching products found. Try different keywords.';
    } else {
      answer = `Here are some products that may match "${q}".`;
    }

    const ids = results.map((p) => p._id);
    const order = new Map(ids.map((id, i) => [String(id), i]));
    let productsOut = await Product.find({ _id: { $in: ids } })
      .select('-embedding')
      .populate('category', 'name slug')
      .populate('subcategory', 'name slug')
      .lean();
    productsOut.sort((a, b) => (order.get(String(a._id)) ?? 0) - (order.get(String(b._id)) ?? 0));
    productsOut = filterProductsByBudget(productsOut, budget);

    res.json({
      answer,
      products: productsOut,
      meta: {
        usedVectorSearch: usedVector,
        semanticQuery: parsed.semanticQuery,
        embedInput,
        budget: { maxPrice: parsed.maxPrice ?? null, minPrice: parsed.minPrice ?? null }
      }
    });
  } catch (err) {
    console.error(err);
    next(err);
  }
};


exports.getSuggestions = async (req, res, next) => {
  try {
    const { q } = req.query;
    if (!q || q.trim().length < 2) return res.json({ suggestions: [] });
    const regex = new RegExp(escapeRegex(q.trim()), 'i');

    const [products, categories] = await Promise.all([
      Product.find({ name: regex, isActive: true }, 'name').limit(6).lean(),
      Category.find({ name: regex, isActive: true }, 'name').limit(3).lean(),
    ]);

    const suggestions = [
      ...products.map(p => ({ type: 'product', text: p.name, id: p._id })),
      ...categories.map(c => ({ type: 'category', text: c.name, id: c._id })),
    ];
    res.json({ suggestions });
  } catch (err) {
    next(err);
  }
};
