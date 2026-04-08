import '../../domain/entities/return_request.dart';

class ReturnRequestModel extends ReturnRequest {
  const ReturnRequestModel({
    required super.id,
    required super.orderId,
    required super.type,
    required super.status,
    required super.reason,
    required super.reasonDetail,
    required super.videoUrl,
    required super.exchangeSize,
    required super.exchangeColor,
    required super.items,
    required super.adminNote,
    required super.rejectReason,
    required super.pickupCourier,
    required super.pickupAwb,
    super.refundAmount,
    required super.exchangeAwb,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ReturnRequestModel.fromJson(Map<String, dynamic> json) {
    final order = json['order'];
    String orderId;
    if (order is Map) {
      orderId = order['_id'].toString();
    } else {
      orderId = order?.toString() ?? '';
    }

    final rawLines = json['items'] as List? ?? [];
    final lines = rawLines.map((e) {
      final m = e as Map<String, dynamic>;
      return ReturnLine(
        orderItemId: m['orderItemId']?.toString(),
        itemIndex: (m['itemIndex'] as num?)?.toInt(),
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
      );
    }).toList();

    final ex = json['exchangeFor'] as Map<String, dynamic>?;

    return ReturnRequestModel(
      id: json['_id'].toString(),
      orderId: orderId,
      type: json['type']?.toString() ?? 'return',
      status: json['status']?.toString() ?? 'requested',
      reason: json['reason']?.toString() ?? '',
      reasonDetail: json['reasonDetail']?.toString() ?? '',
      videoUrl: json['videoUrl']?.toString() ?? '',
      exchangeSize: ex?['size']?.toString() ?? '',
      exchangeColor: ex?['color']?.toString() ?? '',
      items: lines,
      adminNote: json['adminNote']?.toString() ?? '',
      rejectReason: json['rejectReason']?.toString() ?? '',
      pickupCourier: json['pickupCourier']?.toString() ?? '',
      pickupAwb: json['pickupAwb']?.toString() ?? '',
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      exchangeAwb: json['exchangeAwb']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
