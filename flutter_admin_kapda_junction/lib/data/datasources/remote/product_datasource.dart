import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/product_model.dart';

class ProductDataSource {
  final ApiClient _client;
  ProductDataSource(this._client);

  Future<({List<ProductModel> products, int total, int pages})> getProducts({
    int page = 1, int limit = 20, String? search, String? category,
  }) async {
    final res = await _client.get(ApiConstants.products, params: {
      'page': page, 'limit': limit,
      if (search?.isNotEmpty == true) 'search': search,
      if (category != null) 'category': category,
    });
    final data = res.data as Map<String, dynamic>;
    final list = (data['products'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
    return (
      products: list,
      total: (data['total'] as num?)?.toInt() ?? list.length,
      pages: (data['pages'] as num?)?.toInt() ?? 1,
    );
  }

  Future<ProductModel> getProduct(String id) async {
    final res = await _client.get('${ApiConstants.products}/$id');
    final data = res.data;
    final map = data is Map<String, dynamic>
        ? (data['product'] as Map<String, dynamic>? ?? data)
        : data as Map<String, dynamic>;
    return ProductModel.fromJson(map);
  }

  Future<ProductModel> createProduct(Map<String, dynamic> body) async {
    final res = await _client.post(ApiConstants.products, data: body);
    final data = res.data as Map<String, dynamic>;
    return ProductModel.fromJson(data['product'] as Map<String, dynamic>? ?? data);
  }

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> body) async {
    final res = await _client.put('${ApiConstants.products}/$id', data: body);
    final data = res.data as Map<String, dynamic>;
    return ProductModel.fromJson(data['product'] as Map<String, dynamic>? ?? data);
  }

  Future<void> deleteProduct(String id) =>
      _client.delete('${ApiConstants.products}/$id');
}
