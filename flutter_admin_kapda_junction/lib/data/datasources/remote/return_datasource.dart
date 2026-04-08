import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../domain/entities/return_request.dart';

class ReturnDataSource {
  final ApiClient _client;
  ReturnDataSource(this._client);

  Future<List<AdminReturnRequest>> getAll() async {
    final res = await _client.get(ApiConstants.returns);
    final data = res.data;
    if (data is! List) return [];
    return data.map((e) => _parse(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<AdminReturnRequest> update(String id, Map<String, dynamic> body) async {
    final res = await _client.put('${ApiConstants.returns}/$id', data: body);
    return _parse(Map<String, dynamic>.from(res.data as Map));
  }

  AdminReturnRequest _parse(Map<String, dynamic> json) {
    final order = json['order'];
    final orderId = order is Map ? order['_id'].toString() : order.toString();

    var orderStatus = '';
    var orderPaymentStatus = '';
    var orderTotalAmount = 0.0;
    DateTime? orderCreatedAt;
    var orderCancelReason = '';
    DateTime? orderCancelledAt;
    var orderRefundStatus = '';
    double? orderRefundAmount;
    if (order is Map) {
      final om = Map<String, dynamic>.from(order);
      orderStatus = om['status']?.toString() ?? '';
      orderPaymentStatus = om['paymentStatus']?.toString() ?? '';
      orderTotalAmount = (om['totalAmount'] as num?)?.toDouble() ?? 0;
      orderCancelReason = om['cancelReason']?.toString() ?? '';
      orderRefundStatus = om['refundStatus']?.toString() ?? '';
      orderRefundAmount = (om['refundAmount'] as num?)?.toDouble();
      final oc = om['createdAt']?.toString();
      if (oc != null) orderCreatedAt = DateTime.tryParse(oc);
      final ocx = om['cancelledAt']?.toString();
      if (ocx != null) orderCancelledAt = DateTime.tryParse(ocx);
    }

    var exchangeSize = '';
    var exchangeColor = '';
    final ex = json['exchangeFor'];
    if (ex is Map) {
      exchangeSize = ex['size']?.toString() ?? '';
      exchangeColor = ex['color']?.toString() ?? '';
    }

    final user = json['user'];
    String userName = '';
    String userEmail = '';
    if (user is Map) {
      userName = user['name']?.toString() ?? '';
      userEmail = user['email']?.toString() ?? '';
    }

    final rawLines = json['items'] as List? ?? [];
    final items = rawLines.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return AdminReturnLine(
        orderItemId: m['orderItemId']?.toString(),
        itemIndex: (m['itemIndex'] as num?)?.toInt(),
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
      );
    }).toList();

    DateTime? updatedAt;
    final ua = json['updatedAt']?.toString();
    if (ua != null) updatedAt = DateTime.tryParse(ua);

    DateTime? pickupScheduledAt;
    final psa = json['pickupScheduledAt']?.toString();
    if (psa != null) pickupScheduledAt = DateTime.tryParse(psa);

    return AdminReturnRequest(
      id: json['_id'].toString(),
      orderId: orderId,
      userName: userName,
      userEmail: userEmail,
      type: json['type']?.toString() ?? 'return',
      status: json['status']?.toString() ?? 'requested',
      reason: json['reason']?.toString() ?? '',
      reasonDetail: json['reasonDetail']?.toString() ?? '',
      videoUrl: json['videoUrl']?.toString() ?? '',
      exchangeSize: exchangeSize,
      exchangeColor: exchangeColor,
      orderStatus: orderStatus,
      orderPaymentStatus: orderPaymentStatus,
      orderTotalAmount: orderTotalAmount,
      orderCreatedAt: orderCreatedAt,
      orderCancelReason: orderCancelReason,
      orderCancelledAt: orderCancelledAt,
      orderRefundStatus: orderRefundStatus,
      orderRefundAmount: orderRefundAmount,
      adminNote: json['adminNote']?.toString() ?? '',
      rejectReason: json['rejectReason']?.toString() ?? '',
      pickupCourier: json['pickupCourier']?.toString() ?? '',
      pickupAwb: json['pickupAwb']?.toString() ?? '',
      exchangeAwb: json['exchangeAwb']?.toString() ?? '',
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      items: items,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: updatedAt,
      pickupScheduledAt: pickupScheduledAt,
    );
  }
}
