import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/banner_model.dart';
import '../../models/category_model.dart';

class HomeRemoteDataSource {
  final ApiClient _client;
  HomeRemoteDataSource(this._client);

  Future<List<BannerModel>> getActiveBanners() async {
    final res = await _client.get(ApiConstants.activeBanners);
    final data = res.data;
    if (data is! Map<String, dynamic>) return [];
    final list = data['banners'] as List? ?? [];
    return list.whereType<Map<String, dynamic>>().map(BannerModel.fromJson).toList();
  }

  Future<List<CategoryModel>> getCategoryTree() async {
    final res = await _client.get(ApiConstants.categoriesTree);
    final data = res.data;
    final List list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      list = data['categories'] as List? ?? [];
    } else {
      return [];
    }
    return list.whereType<Map<String, dynamic>>().map(CategoryModel.fromJson).toList();
  }

  Future<Map<String, dynamic>> getSettings() async {
    final res = await _client.get(ApiConstants.settings);
    return res.data as Map<String, dynamic>;
  }
}
