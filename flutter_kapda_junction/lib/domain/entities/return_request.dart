import 'package:equatable/equatable.dart';

class ReturnLine extends Equatable {
  final String? orderItemId;
  final int? itemIndex;
  final int quantity;

  const ReturnLine({
    this.orderItemId,
    this.itemIndex,
    required this.quantity,
  });

  @override
  List<Object?> get props => [orderItemId, itemIndex, quantity];
}

class ReturnRequest extends Equatable {
  final String id;
  final String orderId;
  final String type;
  final String status;
  final String reason;
  final String reasonDetail;
  final String videoUrl;
  final String exchangeSize;
  final String exchangeColor;
  final List<ReturnLine> items;
  final String adminNote;
  final String rejectReason;
  final String pickupCourier;
  final String pickupAwb;
  final double? refundAmount;
  final String exchangeAwb;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReturnRequest({
    required this.id,
    required this.orderId,
    required this.type,
    required this.status,
    required this.reason,
    required this.reasonDetail,
    required this.videoUrl,
    required this.exchangeSize,
    required this.exchangeColor,
    required this.items,
    required this.adminNote,
    required this.rejectReason,
    required this.pickupCourier,
    required this.pickupAwb,
    this.refundAmount,
    required this.exchangeAwb,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTerminal {
    const t = ['rejected', 'refunded', 'completed', 'cancelled'];
    return t.contains(status);
  }

  @override
  List<Object?> get props => [id];
}
