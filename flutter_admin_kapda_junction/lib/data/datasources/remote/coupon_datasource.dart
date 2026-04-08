import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../domain/entities/coupon.dart';

class CouponDataSource {
  final ApiClient _client;
  CouponDataSource(this._client);

  Future<List<Coupon>> getAll() async {
    final res = await _client.get(ApiConstants.coupons);
    final data = res.data;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Coupon.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> create(Map<String, dynamic> body) async {
    await _client.post(ApiConstants.coupons, data: body);
  }

  Future<void> update(String id, Map<String, dynamic> body) async {
    await _client.put('${ApiConstants.coupons}/$id', data: body);
  }

  Future<void> delete(String id) async {
    await _client.delete('${ApiConstants.coupons}/$id');
  }
}
