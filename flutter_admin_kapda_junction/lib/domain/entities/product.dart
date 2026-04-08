import 'package:equatable/equatable.dart';

class ProductVariant extends Equatable {
  final String? id;
  final String color;
  final String size;
  final int stock;
  final String? sku;

  const ProductVariant({this.id, required this.color, required this.size, required this.stock, this.sku});

  @override
  List<Object?> get props => [id, color, size, stock];
}

class Product extends Equatable {
  final String id;
  final String name;
  final String? slug;
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
  final int? heroOrder;
  final DateTime? createdAt;

  const Product({
    required this.id, required this.name, this.slug, this.description,
    required this.price, this.compareAtPrice, this.categoryId, this.categoryName,
    required this.images, this.colorImages = const {}, required this.variants, required this.soldOut,
    required this.isActive, required this.isFeatured, this.heroTag, this.heroOrder,
    this.createdAt,
  });

  String? get thumbnailUrl => images.isNotEmpty ? images.first : null;

  @override
  List<Object?> get props => [id, name, price];
}
