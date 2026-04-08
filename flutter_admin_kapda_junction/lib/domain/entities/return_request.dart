import 'package:equatable/equatable.dart';

class AdminReturnLine extends Equatable {
  final String? orderItemId;
  final int? itemIndex;
  final int quantity;
  const AdminReturnLine({
    this.orderItemId,
    this.itemIndex,
    required this.quantity,
  });
  @override
  List<Object?> get props => [orderItemId, itemIndex, quantity];
}

class AdminReturnRequest extends Equatable {
  final String id;
  final String orderId;
  final String userName;
  final String userEmail;
  final String type;
  final String status;
  final String reason;
  final String reasonDetail;
  final String videoUrl;
  final String exchangeSize;
  final String exchangeColor;
  /// Snapshot from populated order (cancel / payment context).
  final String orderStatus;
  final String orderPaymentStatus;
  final double orderTotalAmount;
  final DateTime? orderCreatedAt;
  final String orderCancelReason;
  final DateTime? orderCancelledAt;
  final String orderRefundStatus;
  final double? orderRefundAmount;
  final String adminNote;
  final String rejectReason;
  final String pickupCourier;
  final String pickupAwb;
  final String exchangeAwb;
  final double? refundAmount;
  final List<AdminReturnLine> items;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? pickupScheduledAt;

  const AdminReturnRequest({
    required this.id,
    required this.orderId,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.status,
    required this.reason,
    required this.reasonDetail,
    required this.videoUrl,
    required this.exchangeSize,
    required this.exchangeColor,
    required this.orderStatus,
    required this.orderPaymentStatus,
    required this.orderTotalAmount,
    this.orderCreatedAt,
    required this.orderCancelReason,
    this.orderCancelledAt,
    required this.orderRefundStatus,
    this.orderRefundAmount,
    required this.adminNote,
    required this.rejectReason,
    required this.pickupCourier,
    required this.pickupAwb,
    required this.exchangeAwb,
    this.refundAmount,
    required this.items,
    required this.createdAt,
    this.updatedAt,
    this.pickupScheduledAt,
  });

  @override
  List<Object?> get props => [id];
}
