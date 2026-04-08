import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/banner_model.dart';

class BannerDataSource {
  final ApiClient _client;
  BannerDataSource(this._client);

  Future<List<AppBannerModel>> getAll() async {
    final res = await _client.get(ApiConstants.banners);
    final data = res.data;
    final list = data is List ? data : (data as Map<String, dynamic>)['banners'] as List? ?? [];
    return list.whereType<Map<String, dynamic>>().map(AppBannerModel.fromJson).toList();
  }

  Future<AppBannerModel> create(Map<String, dynamic> body) async {
    final res = await _client.post(ApiConstants.banners, data: body);
    final data = res.data as Map<String, dynamic>;
    return AppBannerModel.fromJson(data['banner'] as Map<String, dynamic>? ?? data);
  }

  Future<AppBannerModel> update(String id, Map<String, dynamic> body) async {
    final res = await _client.put('${ApiConstants.banners}/$id', data: body);
    final data = res.data as Map<String, dynamic>;
    return AppBannerModel.fromJson(data['banner'] as Map<String, dynamic>? ?? data);
  }

  Future<void> delete(String id) => _client.delete('${ApiConstants.banners}/$id');
}
