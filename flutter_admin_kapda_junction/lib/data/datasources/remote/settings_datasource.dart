import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class SettingsDataSource {
  final ApiClient _client;
  SettingsDataSource(this._client);

  Future<Map<String, dynamic>> getAllSettings() async {
    final res = await _client.get(ApiConstants.settings);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> body) async {
    final res = await _client.put(ApiConstants.settings, data: body);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> sendUserNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    final payload = <String, dynamic>{
      'userId': userId,
      'title': title,
      'body': body,
      if (data != null && data.isNotEmpty) 'data': data,
      if ((imageUrl ?? '').trim().isNotEmpty) 'imageUrl': imageUrl!.trim(),
    };
    final res = await _client.post(ApiConstants.sendUserNotification, data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    // Aggregate from available endpoints
    final res = await _client.get('/orders');
    final data = res.data;
    final orders = data is List ? data : (data as Map<String, dynamic>)['orders'] as List? ?? [];
    final total = orders.length;
    final pending = orders.where((o) => (o as Map)['status'] == 'pending').length;
    final revenue = orders.fold<double>(0, (sum, o) {
      final amt = (o as Map)['totalAmount'];
      return sum + ((amt as num?)?.toDouble() ?? 0);
    });
    return {'totalOrders': total, 'pendingOrders': pending, 'revenue': revenue};
  }
}
