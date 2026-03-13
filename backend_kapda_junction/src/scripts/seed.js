/**
 * Seed script – 100+ products, 7 categories, 6 banners
 * Run: npm run seed
 */
require('dotenv').config();
const connectDB = require('../config/database');

const Category = require('../models/Category');
const Product = require('../models/Product');
const Banner = require('../models/Banner');

// Placeholder images (Unsplash – free to use)
const IMAGES = {
  jeans: [
    'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=800',
    'https://images.unsplash.com/photo-1604176354204-9268737828e4?w=800',
    'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=800',
    'https://images.unsplash.com/photo-1605522509905-fdcf0b6c8e93?w=800',
    'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=800',
  ],
  tshirt: [
    'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800',
    'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=800',
    'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=800',
    'https://images.unsplash.com/photo-1562157873-818bc0726f68?w=800',
    'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=800',
  ],
  shirt: [
    'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=800',
    'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=800',
    'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800',
    'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=800',
  ],
  jacket: [
    'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800',
    'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800',
    'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=800',
    'https://images.unsplash.com/photo-1544022613-e87ca75a784a?w=800',
  ],
  belt: [
    'https://images.unsplash.com/photo-1624222247344-550fb60583c2?w=800',
    'https://images.unsplash.com/photo-1591561954557-26941169b49e?w=800',
    'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800',
    'https://images.unsplash.com/photo-1617137968427-85924c800a22?w=800',
  ],
  purse: [
    'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800',
    'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=800',
    'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800',
    'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=800',
  ],
  perfume: [
    'https://images.unsplash.com/photo-1541643600914-78b084683601?w=800',
    'https://images.unsplash.com/photo-1592945403244-b3fbafd0f2c2?w=800',
    'https://images.unsplash.com/photo-1619994121345-b56e1c5e0e0b?w=800',
    'https://images.unsplash.com/photo-1587017539504-67cfbddac569?w=800',
    'https://images.unsplash.com/photo-1595425970377-c9703cf48b6d?w=800',
  ],
};

const COLORS = ['Blue', 'Black', 'White', 'Grey', 'Navy', 'Maroon', 'Olive', 'Beige', 'Brown', 'Red', 'Tan', 'Burgundy'];
const SIZES_JEANS = ['28', '30', '32', '34', '36'];
const SIZES_TOP = ['S', 'M', 'L', 'XL'];
const SIZES_BELT = ['32', '34', '36', '38', '40'];
const PERFUME_VOL = ['30ml', '50ml', '100ml'];

const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
const rand = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

const seed = async () => {
  await connectDB();

  await Product.deleteMany({});
  await Banner.deleteMany({});
  await Category.deleteMany({});

  // 7 Categories
  const catJeans = await Category.create({ name: 'Jeans', slug: 'jeans', sortOrder: 1 });
  const catTshirt = await Category.create({ name: 'T-Shirts', slug: 't-shirts', sortOrder: 2 });
  const catShirt = await Category.create({ name: 'Shirts', slug: 'shirts', sortOrder: 3 });
  const catJacket = await Category.create({ name: 'Jackets', slug: 'jackets', sortOrder: 4 });
  const catBelt = await Category.create({ name: 'Belts', slug: 'belts', sortOrder: 5 });
  const catPurse = await Category.create({ name: 'Purses & Wallets', slug: 'purses-wallets', sortOrder: 6 });
  const catPerfume = await Category.create({ name: 'Perfumes', slug: 'perfumes', sortOrder: 7 });

  const categories = [
    { cat: catJeans, imgs: IMAGES.jeans, sizes: SIZES_JEANS },
    { cat: catTshirt, imgs: IMAGES.tshirt, sizes: SIZES_TOP },
    { cat: catShirt, imgs: IMAGES.shirt, sizes: SIZES_TOP },
    { cat: catJacket, imgs: IMAGES.jacket, sizes: SIZES_TOP },
    { cat: catBelt, imgs: IMAGES.belt, sizes: SIZES_BELT },
    { cat: catPurse, imgs: IMAGES.purse, sizes: ['One Size'] },
    { cat: catPerfume, imgs: IMAGES.perfume, sizes: PERFUME_VOL },
  ];

  const productTemplates = {
    jeans: ['Slim Fit Jeans', 'Regular Fit Jeans', 'Straight Fit Jeans', 'Skinny Jeans', 'Bootcut Jeans', 'Relaxed Fit Jeans', 'Tapered Jeans', 'Stretch Denim', 'Classic Denim', 'Dark Wash Jeans'],
    tshirt: ['Basic Cotton Tee', 'Polo T-Shirt', 'V-Neck Tee', 'Crew Neck Tee', 'Henley Shirt', 'Graphic Tee', 'Striped Tee', 'Pocket Tee', 'Premium Tee', 'Essential Tee'],
    shirt: ['Formal Cotton Shirt', 'Linen Casual Shirt', 'Checked Shirt', 'Solid Oxford Shirt', 'Denim Shirt', 'Flannel Shirt', 'Slim Fit Shirt', 'Office Shirt', 'Weekend Shirt'],
    jacket: ['Denim Jacket', 'Bomber Jacket', 'Leather Jacket', 'Puffer Jacket', 'Blazer', 'Track Jacket', 'Harrington Jacket', 'Windbreaker', 'Coach Jacket', 'Utility Jacket'],
    belt: ['Classic Leather Belt', 'Formal Belt', 'Casual Belt', 'Reversible Belt', 'Buckle Belt', 'Slim Belt', 'Woven Belt', 'Dress Belt', 'Canvas Belt', 'Premium Belt'],
    purse: ['Leather Wallet', 'Bifold Wallet', 'Slim Wallet', 'Card Holder', 'Travel Wallet', 'Money Clip', 'Clutch', 'Crossbody Bag', 'Messenger Bag', 'Leather Purse'],
    perfume: ['Eau de Toilette', 'Eau de Parfum', 'Cologne', 'Body Spray', 'Signature Scent', 'Fresh Fragrance', 'Woody Scent', 'Citrus Fragrance', 'Sport Perfume', 'Luxury Perfume'],
  };

  const brands = {
    default: ['Levis', 'Wrangler', 'Lee', 'Calvin Klein', 'Tommy Hilfiger', 'Nike', 'Zara', 'H&M', 'Arrow', 'Peter England', 'Allen Solly', 'Roadster'],
    belt: ['Fossil', 'Tommy Hilfiger', 'Calvin Klein', 'Arrow', 'Louis Philippe', 'Levis', 'Wrangler', 'American Eagle'],
    purse: ['Fossil', 'Tommy Hilfiger', 'Calvin Klein', 'Coach', 'Michael Kors', 'Louis Philippe', 'American Tourister'],
    perfume: ['Davidoff', 'Axe', 'Fogg', 'Wild Stone', 'Park Avenue', 'Engage', 'Calvin Klein', 'Tommy Hilfiger', 'Hugo Boss', 'Dior', 'Chanel'],
  };

  const allProducts = [];
  let skuCounter = 0;

  for (let i = 0; i < 100; i++) {
    const catIdx = i % 7;
    const { cat, imgs, sizes } = categories[catIdx];
    const keys = ['jeans', 'tshirt', 'shirt', 'jacket', 'belt', 'purse', 'perfume'];
    const key = keys[catIdx];
    const templates = productTemplates[key];
    const brandList = brands[key] || brands.default;

    const name = `${pick(brandList)} ${templates[i % templates.length]}`;
    const price = key === 'perfume' ? rand(499, 3999) : key === 'belt' || key === 'purse' ? rand(599, 2999) : rand(499, 4999);
    const compareAt = price + rand(200, 800);
    const numVariants = key === 'purse' ? rand(1, 4) : rand(2, 5);
    const variants = [];
    const usedCombos = new Set();

    for (let v = 0; v < numVariants; v++) {
      const color = pick(COLORS);
      const size = pick(sizes);
      const combo = `${color}-${size}`;
      if (usedCombos.has(combo)) continue;
      usedCombos.add(combo);
      skuCounter++;
      variants.push({
        color,
        size,
        stock: rand(1, 15),
        sku: `sku-${skuCounter}-${i}-${v}`,
      });
    }

    const p = await Product.create({
      name,
      description: `Premium quality ${name.toLowerCase()}. ${key === 'perfume' ? 'Long-lasting fragrance.' : 'Comfortable and stylish.'}`,
      price,
      compareAtPrice: compareAt,
      category: cat._id,
      images: [pick(imgs)],
      variants,
      isFeatured: i < 12,
    });
    allProducts.push(p);
  }

  // 6 Banners
  const bannerImages = [
    'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=1920',
    'https://images.unsplash.com/photo-1543269865-cbf427effbad?w=1920',
    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1920',
    'https://images.unsplash.com/photo-1445205170230-053b83016050?w=1920',
    'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=1920',
    'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=1920',
  ];

  for (let b = 0; b < 6; b++) {
    const start = b * 4;
    await Banner.create({
      image: bannerImages[b],
      products: allProducts.slice(start, start + 4).map((p) => p._id),
      sortOrder: b,
      isActive: true,
    });
  }

  console.log('✅ Seed complete:');
  console.log('   - 7 categories (Jeans, T-Shirts, Shirts, Jackets, Belts, Purses & Wallets, Perfumes)');
  console.log('   - 100 products');
  console.log('   - 6 banners');
  process.exit(0);
};

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
