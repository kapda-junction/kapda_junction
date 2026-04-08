import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class ActivityDataSource {
  final ApiClient _client;
  ActivityDataSource(this._client);

  /// Fire-and-forget — never throws
  Future<void> trackSearch(String query) async {
    try {
      await _client.post(ApiConstants.activitySearch, data: {'query': query});
    } catch (_) {}
  }

  Future<void> trackView(String productId, String productName, String? productImage) async {
    try {
      await _client.post(ApiConstants.activityView, data: {
        'productId': productId,
        'productName': productName,
        'productImage': productImage,
      });
    } catch (_) {}
  }

  Future<List<String>> getRecentSearches() async {
    try {
      final res = await _client.get(ApiConstants.recentSearches);
      final data = res.data as Map<String, dynamic>;
      return (data['searches'] as List? ?? []).map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> getSuggestions(String query) async {
    try {
      final res = await _client.get(ApiConstants.suggestions, params: {'q': query});
      final data = res.data as Map<String, dynamic>;
      return (data['suggestions'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => e['text']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
