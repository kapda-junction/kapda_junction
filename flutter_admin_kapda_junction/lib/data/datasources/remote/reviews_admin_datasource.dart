import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class ReviewsAdminDataSource {
  final ApiClient _client;
  ReviewsAdminDataSource(this._client);

  Future<List<Map<String, dynamic>>> list({String? status}) async {
    final res = await _client.get(
      '${ApiConstants.reviews}/admin',
      params: {if (status != null) 'status': status},
    );
    final data = res.data;
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> moderate(String id, String status, {String? adminNote}) async {
    final res = await _client.put(
      '${ApiConstants.reviews}/admin/$id',
      data: {
        'status': status,
        if (adminNote != null) 'adminNote': adminNote,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
