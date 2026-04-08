import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/option_models.dart';

class OptionsDataSource {
  final ApiClient _client;
  OptionsDataSource(this._client);

  // Colors
  Future<List<ColorOptionModel>> getColors() async {
    final res = await _client.get(ApiConstants.colors);
    final data = res.data;
    final list = data is List ? data : (data as Map<String, dynamic>)['colors'] as List? ?? [];
    return list.whereType<Map<String, dynamic>>().map(ColorOptionModel.fromJson).toList();
  }

  Future<ColorOptionModel> createColor(String name) async {
    final res = await _client.post(ApiConstants.colors, data: {'name': name});
    return ColorOptionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ColorOptionModel> updateColor(String id, String name) async {
    final res = await _client.put('${ApiConstants.colors}/$id', data: {'name': name});
    return ColorOptionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteColor(String id) => _client.delete('${ApiConstants.colors}/$id');

  // Sizes
  Future<List<SizeOptionModel>> getSizes() async {
    final res = await _client.get(ApiConstants.sizes);
    final data = res.data;
    final list = data is List ? data : (data as Map<String, dynamic>)['sizes'] as List? ?? [];
    return list.whereType<Map<String, dynamic>>().map(SizeOptionModel.fromJson).toList();
  }

  Future<SizeOptionModel> createSize(String name) async {
    final res = await _client.post(ApiConstants.sizes, data: {'name': name});
    return SizeOptionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SizeOptionModel> updateSize(String id, String name) async {
    final res = await _client.put('${ApiConstants.sizes}/$id', data: {'name': name});
    return SizeOptionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteSize(String id) => _client.delete('${ApiConstants.sizes}/$id');
}
