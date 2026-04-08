import '../../domain/entities/order.dart';

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    super.lineItemId,
    required super.productId,
    required super.name,
    required super.price,
    required super.quantity,
    super.size,
    super.color,
    super.image,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final lineId = json['_id']?.toString();
    final product = json['product'];
    String productId;
    String? image;
    if (product is Map<String, dynamic>) {
      productId = product['_id'].toString();
      final images = product['images'] as List?;
      image = images?.isNotEmpty == true ? images!.first.toString() : null;
    } else {
      productId = product.toString();
    }

    return OrderItemModel(
      lineItemId: lineId,
      productId: productId,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      size: json['size'] as String?,
      color: json['color'] as String?,
      image: image,
    );
  }
}

class ShippingAddressModel extends ShippingAddress {
  const ShippingAddressModel({
    required super.name,
    required super.phone,
    required super.address,
    required super.city,
    required super.state,
    required super.pincode,
  });

  factory ShippingAddressModel.fromJson(Map<String, dynamic> json) {
    return ShippingAddressModel(
      name: json['name'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
      };
}

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.items,
    required super.status,
    required super.subtotal,
    required super.discountAmount,
    required super.couponCode,
    required super.totalAmount,
    required super.shippingAddress,
    required super.paymentStatus,
    super.razorpayOrderId,
    super.razorpayPaymentId,
    required super.createdAt,
    required super.updatedAt,
    super.cancelReason,
    super.shippingCarrier,
    super.shippingAwb,
    super.trackingUrl,
    super.shippedAt,
    super.razorpayRefundId,
    super.refundStatus,
    super.refundAmount,
    super.refundLastError,
    super.refundNote,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final items = rawItems
        .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
        .toList();
    final user = json['user'];
    final userId = user is Map ? user['_id'].toString() : user.toString();

    final totalAmount = (json['totalAmount'] as num).toDouble();
    final discountAmount = (json['discountAmount'] as num?)?.toDouble() ?? 0;
    final storedSubtotal = (json['subtotal'] as num?)?.toDouble();
    final lineSum =
        items.fold<double>(0, (s, i) => s + i.subtotal);
    final subtotal = storedSubtotal ??
        (discountAmount > 0 ? totalAmount + discountAmount : lineSum);

    return OrderModel(
      id: json['_id'].toString(),
      userId: userId,
      items: items,
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      subtotal: subtotal,
      discountAmount: discountAmount,
      couponCode: json['couponCode'] as String? ?? '',
      totalAmount: totalAmount,
      shippingAddress: ShippingAddressModel.fromJson(
          json['shippingAddress'] as Map<String, dynamic>),
      paymentStatus:
          _parsePaymentStatus(json['paymentStatus'] as String? ?? 'pending'),
      razorpayOrderId: json['razorpayOrderId'] as String?,
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      cancelReason: json['cancelReason'] as String?,
      shippingCarrier: json['shippingCarrier'] as String? ?? '',
      shippingAwb: json['shippingAwb'] as String? ?? '',
      trackingUrl: json['trackingUrl'] as String?,
      shippedAt: json['shippedAt'] != null
          ? DateTime.tryParse(json['shippedAt'] as String)
          : null,
      razorpayRefundId: json['razorpayRefundId'] as String?,
      refundStatus: json['refundStatus'] as String?,
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      refundLastError: json['refundLastError'] as String?,
      refundNote: json['refundNote'] as String?,
    );
  }

  static OrderStatus _parseStatus(String s) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => OrderStatus.pending,
    );
  }

  static PaymentStatus _parsePaymentStatus(String s) {
    const map = {
      'pending': PaymentStatus.pending,
      'paid': PaymentStatus.paid,
      'failed': PaymentStatus.failed,
      'refunded': PaymentStatus.refunded,
      'partially_refunded': PaymentStatus.partiallyRefunded,
    };
    return map[s] ?? PaymentStatus.pending;
  }
}
