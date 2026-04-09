import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class ReviewRemoteDataSource {
  final ApiClient _client;
  ReviewRemoteDataSource(this._client);

  Future<Map<String, dynamic>> getProductReviews(String productId) async {
    final res =
        await _client.get('${ApiConstants.reviews}/product/$productId');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> createReview({
    required String orderId,
    required String productId,
    required int rating,
    String title = '',
    String body = '',
  }) async {
    await _client.post(
      ApiConstants.reviews,
      data: {
        'orderId': orderId,
        'productId': productId,
        'rating': rating,
        'title': title,
        'body': body,
      },
      skipGlobalError: true,
    );
  }

  /// For [orderId], maps product id → review status (`pending`, `approved`, `rejected`)
  /// from GET /reviews/mine.
  Future<Map<String, String>> reviewStatusByProductForOrder(
    String orderId,
  ) async {
    try {
      final res = await _client.get(
        '${ApiConstants.reviews}/mine',
        skipGlobalError: true,
      );
      final data = res.data;
      if (data is! List) return {};
      final oid = orderId.trim();
      final out = <String, String>{};
      for (final raw in data) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final orderField = m['order'];
        String? o;
        if (orderField is Map) {
          o = orderField['_id']?.toString();
        } else if (orderField != null) {
          o = orderField.toString();
        }
        if (o != oid) continue;
        final productField = m['product'];
        String? p;
        if (productField is Map) {
          p = productField['_id']?.toString();
        } else if (productField != null) {
          p = productField.toString();
        }
        if (p == null || p.isEmpty) continue;
        final st = (m['status'] ?? 'pending').toString().toLowerCase();
        out[p] = st;
      }
      return out;
    } catch (_) {
      return {};
    }
  }
}
