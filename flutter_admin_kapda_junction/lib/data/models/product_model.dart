import '../../domain/entities/product.dart';

class ProductVariantModel extends ProductVariant {
  const ProductVariantModel({super.id, required super.color, required super.size, required super.stock, super.sku});

  factory ProductVariantModel.fromJson(Map<String, dynamic> j) => ProductVariantModel(
    id: j['_id'] as String?,
    color: j['color'] as String? ?? '',
    size: j['size'] as String? ?? '',
    stock: (j['stock'] as num?)?.toInt() ?? 0,
    sku: j['sku'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'color': color, 'size': size, 'stock': stock,
    if (sku != null) 'sku': sku,
  };
}

class ProductModel extends Product {
  const ProductModel({
    required super.id, required super.name, super.slug, super.description,
    required super.price, super.compareAtPrice, super.categoryId, super.categoryName,
    required super.images, super.colorImages = const {}, required super.variants,
    required super.soldOut, required super.isActive, required super.isFeatured,
    super.heroTag, super.heroOrder, super.createdAt,
  });

  static Map<String, List<String>> _parseColorImages(dynamic raw) {
    if (raw == null) return {};
    final map = <String, List<String>>{};
    for (final item in (raw as List).whereType<Map<String, dynamic>>()) {
      final color = item['color'] as String?;
      if (color != null && color.isNotEmpty) {
        map[color] = (item['images'] as List? ?? []).map((e) => e.toString()).toList();
      }
    }
    return map;
  }

  factory ProductModel.fromJson(Map<String, dynamic> j) {
    final cat = j['category'];
    return ProductModel(
      id: j['_id'] as String,
      name: j['name'] as String? ?? '',
      slug: j['slug'] as String?,
      description: j['description'] as String?,
      price: (j['price'] as num?)?.toDouble() ?? 0,
      compareAtPrice: (j['compareAtPrice'] as num?)?.toDouble(),
      categoryId: cat is Map ? cat['_id'] as String? : cat as String?,
      categoryName: cat is Map ? cat['name'] as String? : null,
      images: (j['images'] as List? ?? []).map((e) => e.toString()).toList(),
      colorImages: _parseColorImages(j['colorImages']),
      variants: (j['variants'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProductVariantModel.fromJson)
          .toList(),
      soldOut: j['soldOut'] as bool? ?? false,
      isActive: j['isActive'] as bool? ?? true,
      isFeatured: j['isFeatured'] as bool? ?? false,
      heroTag: j['heroTag'] as String?,
      heroOrder: (j['heroOrder'] as num?)?.toInt(),
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    'price': price,
    if (compareAtPrice != null) 'compareAtPrice': compareAtPrice,
    if (categoryId != null) 'category': categoryId,
    'images': images,
    'variants': variants.map((v) => (v as ProductVariantModel).toJson()).toList(),
    'isActive': isActive,
    'isFeatured': isFeatured,
    if (heroTag != null) 'heroTag': heroTag,
    if (heroOrder != null) 'heroOrder': heroOrder,
  };
}
