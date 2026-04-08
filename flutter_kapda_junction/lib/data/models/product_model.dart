import '../../domain/entities/product.dart';

class ProductVariantModel extends ProductVariant {
  const ProductVariantModel({
    super.color,
    super.size,
    required super.stock,
    super.sku,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      color: json['color'] as String?,
      size: json['size'] as String?,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      sku: json['sku'] as String?,
    );
  }
}

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.slug,
    super.description,
    required super.price,
    super.compareAtPrice,
    super.categoryId,
    super.categoryName,
    required super.images,
    super.colorImages = const {},
    required super.variants,
    required super.soldOut,
    required super.isActive,
    required super.isFeatured,
    super.heroTag,
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

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    String? categoryId;
    String? categoryName;
    if (category is Map<String, dynamic>) {
      categoryId = category['_id'] as String?;
      categoryName = category['name'] as String?;
    } else if (category is String) {
      categoryId = category;
    }

    final rawImages = json['images'] as List? ?? [];
    final images = rawImages.map((e) => e.toString()).toList();

    final rawVariants = json['variants'] as List? ?? [];
    final variants = rawVariants
        .map((v) => ProductVariantModel.fromJson(v as Map<String, dynamic>))
        .toList();

    return ProductModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      compareAtPrice: (json['compareAtPrice'] as num?)?.toDouble(),
      categoryId: categoryId,
      categoryName: categoryName,
      images: images,
      colorImages: _parseColorImages(json['colorImages']),
      variants: variants,
      soldOut: json['soldOut'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      heroTag: (json['heroTag'] as String?)?.isNotEmpty == true ? json['heroTag'] as String : null,
    );
  }
}
