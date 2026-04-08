import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  /// Line id from API (`items[]. _id`) when present — used for returns.
  final String? lineItemId;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? size;
  final String? color;
  final String? image;

  const OrderItem({
    this.lineItemId,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.size,
    this.color,
    this.image,
  });

  double get subtotal => price * quantity;

  @override
  List<Object?> get props => [lineItemId, productId, name, quantity, size, color];
}

class ShippingAddress extends Equatable {
  final String name;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String pincode;

  const ShippingAddress({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
  });

  String get fullAddress => '$address, $city, $state - $pincode';

  @override
  List<Object?> get props => [name, phone, address, city, state, pincode];
}

enum OrderStatus { pending, confirmed, shipped, delivered, cancelled }
enum PaymentStatus { pending, paid, failed, refunded, partiallyRefunded }

class Order extends Equatable {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final OrderStatus status;
  /// Sum of line items before coupon (falls back to [totalAmount] on older API data).
  final double subtotal;
  final double discountAmount;
  final String couponCode;
  final double totalAmount;
  final ShippingAddress shippingAddress;
  final PaymentStatus paymentStatus;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? cancelReason;
  /// India Post / manual — admin fills when marking shipped
  final String shippingCarrier;
  final String shippingAwb;
  final String? trackingUrl;
  final DateTime? shippedAt;
  final String? razorpayRefundId;
  final String? refundStatus;
  final double? refundAmount;
  final String? refundLastError;
  final String? refundNote;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.couponCode,
    required this.totalAmount,
    required this.shippingAddress,
    required this.paymentStatus,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.createdAt,
    required this.updatedAt,
    this.cancelReason,
    this.shippingCarrier = '',
    this.shippingAwb = '',
    this.trackingUrl,
    this.shippedAt,
    this.razorpayRefundId,
    this.refundStatus,
    this.refundAmount,
    this.refundLastError,
    this.refundNote,
  });

  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isCancelled => status == OrderStatus.cancelled;

  @override
  List<Object?> get props => [id];
}
