import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/order_model.dart';

class OrderRemoteDataSource {
  final ApiClient _client;
  OrderRemoteDataSource(this._client);

  Future<List<OrderModel>> getOrders() async {
    final res = await _client.get(ApiConstants.orders);
    final data = res.data;
    List list;
    if (data is List) {
      list = data; // backend returns array directly
    } else if (data is Map<String, dynamic>) {
      list = data['orders'] as List? ?? [];
    } else {
      return [];
    }
    return list.whereType<Map<String, dynamic>>().map(OrderModel.fromJson).toList();
  }

  Future<OrderModel> getOrderById(String id) async {
    final res = await _client.get('${ApiConstants.orders}/$id');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final order = data['order'] is Map<String, dynamic>
          ? data['order'] as Map<String, dynamic>
          : data;
      return OrderModel.fromJson(order);
    }
    throw Exception('Invalid order response');
  }

  Future<Map<String, dynamic>> createPaymentOrder(
      Map<String, dynamic> body) async {
    final res = await _client.post(ApiConstants.createPayment, data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<OrderModel> verifyPayment(Map<String, dynamic> body) async {
    final res = await _client.post(ApiConstants.verifyPayment, data: body);
    final data = res.data as Map<String, dynamic>;
    return OrderModel.fromJson(data['order'] as Map<String, dynamic>);
  }

  Future<void> cancelOrderCustomer(String orderId, {String? reason}) async {
    await _client.put(
      '${ApiConstants.orders}/$orderId/cancel-customer',
      data: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  Future<OrderModel> createOrder(Map<String, dynamic> body) async {
    final res = await _client.post(ApiConstants.orders, data: body);
    final data = res.data as Map<String, dynamic>;
    return OrderModel.fromJson(data['order'] as Map<String, dynamic>);
  }
}
