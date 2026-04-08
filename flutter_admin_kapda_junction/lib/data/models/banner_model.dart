import '../../domain/entities/banner.dart';

class AppBannerModel extends AppBanner {
  const AppBannerModel({
    required super.id, required super.image, required super.products,
    required super.sortOrder, required super.isActive,
  });

  factory AppBannerModel.fromJson(Map<String, dynamic> j) {
    final rawP = j['products'] as List? ?? [];
    final products = rawP.whereType<Map<String, dynamic>>().map((p) {
      final imgs = p['images'] as List? ?? [];
      return BannerProduct(
        id: p['_id'] as String? ?? '',
        name: p['name'] as String? ?? '',
        price: (p['price'] as num?)?.toDouble() ?? 0,
        image: imgs.isNotEmpty ? imgs.first.toString() : null,
      );
    }).toList();
    return AppBannerModel(
      id: j['_id'] as String,
      image: j['image'] as String? ?? '',
      products: products,
      sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: j['isActive'] as bool? ?? true,
    );
  }
}
