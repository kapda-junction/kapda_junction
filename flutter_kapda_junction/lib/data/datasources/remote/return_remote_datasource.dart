import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/return_request_model.dart';

class ReturnRemoteDataSource {
  final ApiClient _client;
  ReturnRemoteDataSource(this._client);

  Future<List<ReturnRequestModel>> list({String? orderId}) async {
    final res = await _client.get(
      ApiConstants.returns,
      params: {if (orderId != null) 'orderId': orderId},
    );
    final data = res.data;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => ReturnRequestModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ReturnRequestModel> create(Map<String, dynamic> body) async {
    final res = await _client.post(ApiConstants.returns, data: body);
    return ReturnRequestModel.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> cancelReturn(String id) async {
    await _client.put('${ApiConstants.returns}/$id/cancel');
  }
}
