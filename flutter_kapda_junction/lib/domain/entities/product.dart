import 'package:equatable/equatable.dart';

class ProductVariant extends Equatable {
  final String? color;
  final String? size;
  final int stock;
  final String? sku;

  const ProductVariant({this.color, this.size, required this.stock, this.sku});

  bool get isAvailable => stock > 0;

  @override
  List<Object?> get props => [color, size, stock, sku];
}

class Product extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? compareAtPrice;
  final String? categoryId;
  final String? categoryName;
  final List<String> images;
  final Map<String, List<String>> colorImages;
  final List<ProductVariant> variants;
  final bool soldOut;
  final bool isActive;
  final bool isFeatured;
  final String? heroTag;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.compareAtPrice,
    this.categoryId,
    this.categoryName,
    required this.images,
    this.colorImages = const {},
    required this.variants,
    required this.soldOut,
    required this.isActive,
    required this.isFeatured,
    this.heroTag,
  });

  String? get thumbnailUrl => images.isNotEmpty ? images.first : null;

  List<String> imagesForColor(String? color) {
    if (color == null || colorImages.isEmpty) return images;
    final imgs = colorImages[color];
    return (imgs != null && imgs.isNotEmpty) ? imgs : images;
  }

  bool get hasDiscount =>
      compareAtPrice != null && compareAtPrice! > price;

  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  List<String> get availableColors => variants
      .where((v) => v.isAvailable && v.color != null)
      .map((v) => v.color!)
      .toSet()
      .toList();

  List<String> sizesForColor(String? color) => variants
      .where((v) => v.isAvailable && (color == null || v.color == color))
      .where((v) => v.size != null)
      .map((v) => v.size!)
      .toSet()
      .toList();

  List<String> allSizesForColor(String? color) => variants
      .where((v) => color == null || v.color == color)
      .where((v) => v.size != null)
      .map((v) => v.size!)
      .toSet()
      .toList();

  bool isVariantAvailable(String? color, String? size) => variants.any(
        (v) =>
            v.isAvailable &&
            (color == null || v.color == color) &&
            (size == null || v.size == size),
      );

  @override
  List<Object?> get props => [id, name, price];
}
