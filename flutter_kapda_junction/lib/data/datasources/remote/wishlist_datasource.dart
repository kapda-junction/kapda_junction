import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/product_model.dart';

class WishlistDataSource {
  final ApiClient _client;
  WishlistDataSource(this._client);

  Future<List<String>> getIds() async {
    final res = await _client.get(ApiConstants.wishlistIds);
    final data = res.data as Map<String, dynamic>;
    return (data['productIds'] as List? ?? []).map((e) => e.toString()).toList();
  }

  Future<List<ProductModel>> getProducts() async {
    final res = await _client.get(ApiConstants.wishlist);
    final data = res.data as Map<String, dynamic>;
    return (data['products'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  Future<void> add(String productId) =>
      _client.post('${ApiConstants.wishlist}/$productId', data: {});

  Future<void> remove(String productId) =>
      _client.delete('${ApiConstants.wishlist}/$productId');

  Future<void> clearAll() =>
      _client.delete(ApiConstants.wishlist);
}
