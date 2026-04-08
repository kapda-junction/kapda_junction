import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/product_model.dart';

class ProductRemoteDataSource {
  final ApiClient _client;
  ProductRemoteDataSource(this._client);

  Future<List<ProductModel>> getProducts({
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? size,
    String? color,
    int page = 1,
    int limit = AppConstants.defaultPageSize,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search?.isNotEmpty == true) 'search': search,
      if (category != null) 'category': category,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (size?.trim().isNotEmpty == true) 'size': size!.trim(),
      if (color?.trim().isNotEmpty == true) 'color': color!.trim(),
    };
    final res = await _client.get(ApiConstants.products, params: params);
    final data = res.data;
    if (data is! Map<String, dynamic>) return [];
    final list = data['products'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((p) => ProductModel.fromJson(p))
        .toList();
  }

  Future<List<ProductModel>> getFeaturedProducts() async {
    final res = await _client.get(ApiConstants.featuredProducts);
    final data = res.data;
    if (data is! Map<String, dynamic>) return [];
    final list = data['products'] as List? ?? [];
    return list.whereType<Map<String, dynamic>>().map(ProductModel.fromJson).toList();
  }

  Future<Map<String, dynamic>> getLandingData() async {
    final res = await _client.get(ApiConstants.landingProducts);
    return res.data as Map<String, dynamic>;
  }

  Future<ProductModel> getProductById(String id) async {
    final res = await _client.get('${ApiConstants.products}/$id');
    final data = res.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid product response');
    // Backend may return {product: {...}} or the product directly
    final product = data['product'] is Map<String, dynamic>
        ? data['product'] as Map<String, dynamic>
        : data;
    return ProductModel.fromJson(product);
  }

  Future<List<ProductModel>> aiSearch(String query) async {
    final res = await _client.post(ApiConstants.aiSearch, data: {'query': query});
    final data = res.data as Map<String, dynamic>;
    final list = data['products'] as List? ?? [];
    return list
        .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }
}
