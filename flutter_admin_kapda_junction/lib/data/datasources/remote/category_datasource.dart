import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/category_model.dart';

class CategoryDataSource {
  final ApiClient _client;
  CategoryDataSource(this._client);

  Future<List<CategoryModel>> getAll() async {
    final res = await _client.get(ApiConstants.categories);
    final data = res.data;
    final list = data is List ? data : (data as Map<String, dynamic>)['categories'] as List? ?? [];
    return list.whereType<Map<String, dynamic>>().map(CategoryModel.fromJson).toList();
  }

  Future<List<CategoryModel>> getTree() async {
    final res = await _client.get(ApiConstants.categoriesTree);
    final data = res.data;
    final list = data is List ? data : (data as Map<String, dynamic>)['categories'] as List? ?? [];
    return list.whereType<Map<String, dynamic>>().map(CategoryModel.fromJson).toList();
  }

  Future<CategoryModel> create(Map<String, dynamic> body) async {
    final res = await _client.post(ApiConstants.categories, data: body);
    return CategoryModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CategoryModel> update(String id, Map<String, dynamic> body) async {
    final res = await _client.put('${ApiConstants.categories}/$id', data: body);
    return CategoryModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _client.delete('${ApiConstants.categories}/$id');
}
