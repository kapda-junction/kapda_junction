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
    await _client.post(ApiConstants.reviews, data: {
      'orderId': orderId,
      'productId': productId,
      'rating': rating,
      'title': title,
      'body': body,
    });
  }
}
