import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/order_model.dart';

class OrderDataSource {
  final ApiClient _client;
  OrderDataSource(this._client);

  Future<List<AdminOrderModel>> getOrders({String? status}) async {
    final res = await _client.get(ApiConstants.orders,
        params: {if (status != null) 'status': status});
    final data = res.data;
    final list = data is List ? data : (data as Map<String, dynamic>)['orders'] as List? ?? [];
    return list.whereType<Map<String, dynamic>>().map(AdminOrderModel.fromJson).toList();
  }

  Future<AdminOrderModel> updateStatus(String id, String status) async {
    final res = await _client.put('${ApiConstants.orders}/$id/status', data: {'status': status});
    final data = res.data as Map<String, dynamic>;
    return AdminOrderModel.fromJson(data['order'] as Map<String, dynamic>? ?? data);
  }

  Future<AdminOrderModel> updateOrderFields(String id, Map<String, dynamic> body) async {
    final res = await _client.put('${ApiConstants.orders}/$id/status', data: body);
    final data = res.data as Map<String, dynamic>;
    return AdminOrderModel.fromJson(data['order'] as Map<String, dynamic>? ?? data);
  }

  Future<AdminOrderModel> retryRefund(String id) async {
    final res = await _client.post('${ApiConstants.orders}/$id/retry-refund');
    final data = res.data as Map<String, dynamic>;
    final order = data['order'] as Map<String, dynamic>?;
    if (order != null) return AdminOrderModel.fromJson(order);
    return AdminOrderModel.fromJson(data);
  }

  Future<AdminOrderModel> cancelOrder(String id, {String? reason, bool refund = false}) async {
    final res = await _client.put('${ApiConstants.orders}/$id/cancel', data: {
      if (reason != null) 'reason': reason,
      'refund': refund,
    });
    final data = res.data as Map<String, dynamic>;
    return AdminOrderModel.fromJson(data['order'] as Map<String, dynamic>? ?? data);
  }
}
