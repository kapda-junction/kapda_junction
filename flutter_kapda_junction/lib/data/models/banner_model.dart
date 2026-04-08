import '../../domain/entities/banner.dart';

class BannerModel extends AppBanner {
  const BannerModel({
    required super.id,
    required super.image,
    required super.products,
    required super.sortOrder,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'] as List? ?? [];
    final products = rawProducts.whereType<Map<String, dynamic>>().map((p) {
      final images = p['images'] as List? ?? [];
      return BannerProduct(
        id: p['_id'].toString(),
        name: p['name'] as String? ?? '',
        image: images.isNotEmpty ? images.first.toString() : null,
        price: (p['price'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    return BannerModel(
      id: json['_id'] as String,
      image: json['image'] as String,
      products: products,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
