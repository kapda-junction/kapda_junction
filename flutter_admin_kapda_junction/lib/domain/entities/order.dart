import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double price;
  final String? color;
  final String? size;

  const OrderItem({
    required this.productId, required this.productName, this.productImage,
    required this.quantity, required this.price, this.color, this.size,
  });

  @override
  List<Object?> get props => [productId, color, size];
}

class ShippingAddress extends Equatable {
  final String name;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;

  const ShippingAddress({
    required this.name, required this.phone, required this.addressLine1,
    this.addressLine2, required this.city, required this.state, required this.pincode,
  });

  String get full => '$addressLine1${addressLine2 != null ? ', $addressLine2' : ''}, $city, $state - $pincode';

  @override
  List<Object?> get props => [name, phone, addressLine1];
}

class AdminOrder extends Equatable {
  final String id;
  final String? userId;
  final String userName;
  final String userEmail;
  final List<OrderItem> items;
  final String status;
  final String paymentStatus;
  final double totalAmount;
  final ShippingAddress? shippingAddress;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? refundStatus;
  final double? refundAmount;
  final String? razorpayRefundId;
  final String? refundLastError;
  final String? refundNote;
  final String? cancelReason;
  final DateTime? createdAt;
  final String shippingCarrier;
  final String shippingAwb;
  final String shippingTrackingUrlOverride;
  final String? trackingUrl;
  final DateTime? shippedAt;

  const AdminOrder({
    required this.id, this.userId, required this.userName, required this.userEmail,
    required this.items, required this.status, required this.paymentStatus,
    required this.totalAmount, this.shippingAddress, this.razorpayOrderId,
    this.razorpayPaymentId, this.refundStatus, this.refundAmount,
    this.razorpayRefundId, this.refundLastError, this.refundNote,
    this.cancelReason, this.createdAt,
    this.shippingCarrier = 'India Post',
    this.shippingAwb = '',
    this.shippingTrackingUrlOverride = '',
    this.trackingUrl,
    this.shippedAt,
  });

  AdminOrder copyWith({String? status}) => AdminOrder(
    id: id, userId: userId, userName: userName, userEmail: userEmail,
    items: items, status: status ?? this.status, paymentStatus: paymentStatus,
    totalAmount: totalAmount, shippingAddress: shippingAddress,
    razorpayOrderId: razorpayOrderId, razorpayPaymentId: razorpayPaymentId,
    refundStatus: refundStatus, refundAmount: refundAmount,
    razorpayRefundId: razorpayRefundId, refundLastError: refundLastError,
    refundNote: refundNote,
    cancelReason: cancelReason, createdAt: createdAt,
    shippingCarrier: shippingCarrier, shippingAwb: shippingAwb,
    shippingTrackingUrlOverride: shippingTrackingUrlOverride,
    trackingUrl: trackingUrl, shippedAt: shippedAt,
  );

  bool get canUpdateStatus => status != 'delivered' && status != 'cancelled';
  bool get canCancel => status != 'delivered' && status != 'cancelled';

  static const List<String> statusFlow = ['pending', 'confirmed', 'shipped', 'delivered'];

  @override
  List<Object?> get props => [id, status];
}
