import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class NotificationDataSource {
  final ApiClient _client;
  NotificationDataSource(this._client);

  Future<List<Map<String, dynamic>>> getAudience({String? search, int limit = 60}) async {
    final res = await _client.get(
      ApiConstants.notificationAudience,
      params: {
        'limit': limit,
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );
    final map = Map<String, dynamic>.from(res.data as Map);
    final users = (map['users'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return users;
  }

  Future<Map<String, dynamic>> send({
    required String audienceType,
    List<String>? userIds,
    String? productId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    final payload = <String, dynamic>{
      'audienceType': audienceType,
      if (userIds != null && userIds.isNotEmpty) 'userIds': userIds,
      if ((productId ?? '').trim().isNotEmpty) 'productId': productId!.trim(),
      'title': title,
      'body': body,
      if (data != null && data.isNotEmpty) 'data': data,
      if ((imageUrl ?? '').trim().isNotEmpty) 'imageUrl': imageUrl!.trim(),
    };
    final res = await _client.post(ApiConstants.sendNotification, data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }
}
