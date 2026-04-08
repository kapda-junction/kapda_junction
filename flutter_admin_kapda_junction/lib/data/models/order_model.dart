import '../../domain/entities/order.dart';

class AdminOrderModel extends AdminOrder {
  const AdminOrderModel({
    required super.id, super.userId, required super.userName, required super.userEmail,
    required super.items, required super.status, required super.paymentStatus,
    required super.totalAmount, super.shippingAddress, super.razorpayOrderId,
    super.razorpayPaymentId, super.refundStatus, super.refundAmount,
    super.razorpayRefundId, super.refundLastError, super.refundNote,
    super.cancelReason, super.createdAt, super.shippingCarrier,
    super.shippingAwb, super.shippingTrackingUrlOverride, super.trackingUrl,
    super.shippedAt,
  });

  factory AdminOrderModel.fromJson(Map<String, dynamic> j) {
    final user = j['user'];
    final addr = j['shippingAddress'];

    ShippingAddress? sa;
    if (addr is Map<String, dynamic>) {
      sa = ShippingAddress(
        name: addr['name'] as String? ?? '',
        phone: addr['phone'] as String? ?? '',
        addressLine1: addr['addressLine1'] as String? ?? '',
        addressLine2: addr['addressLine2'] as String?,
        city: addr['city'] as String? ?? '',
        state: addr['state'] as String? ?? '',
        pincode: addr['pincode'] as String? ?? '',
      );
    }

    final items = (j['items'] as List? ?? []).whereType<Map<String, dynamic>>().map((i) {
      final p = i['product'];
      final imgs = p is Map ? (p['images'] as List? ?? []) : [];
      return OrderItem(
        productId: p is Map ? p['_id'] as String? ?? '' : p?.toString() ?? '',
        productName: p is Map ? p['name'] as String? ?? '' : '',
        productImage: imgs.isNotEmpty ? imgs.first.toString() : null,
        quantity: (i['quantity'] as num?)?.toInt() ?? 1,
        price: (i['price'] as num?)?.toDouble() ?? 0,
        color: i['color'] as String?,
        size: i['size'] as String?,
      );
    }).toList();

    final refStatus = j['refundStatus'];

    return AdminOrderModel(
      id: j['_id'] as String,
      userId: user is Map ? user['_id'] as String? : null,
      userName: user is Map ? user['name'] as String? ?? 'Unknown' : 'Unknown',
      userEmail: user is Map ? user['email'] as String? ?? '' : '',
      items: items,
      status: j['status'] as String? ?? 'pending',
      paymentStatus: j['paymentStatus'] as String? ?? 'pending',
      totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
      shippingAddress: sa,
      razorpayOrderId: j['razorpayOrderId'] as String?,
      razorpayPaymentId: j['razorpayPaymentId'] as String?,
      refundStatus: (refStatus is String && refStatus.isNotEmpty) ? refStatus : null,
      refundAmount: (j['refundAmount'] as num?)?.toDouble(),
      cancelReason: j['cancelReason'] as String?,
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'] as String) : null,
      razorpayRefundId: j['razorpayRefundId'] as String?,
      refundLastError: j['refundLastError'] as String?,
      refundNote: j['refundNote'] as String?,
      shippingCarrier: j['shippingCarrier'] as String? ?? 'India Post',
      shippingAwb: j['shippingAwb'] as String? ?? '',
      shippingTrackingUrlOverride: j['shippingTrackingUrlOverride'] as String? ?? '',
      trackingUrl: j['trackingUrl'] as String?,
      shippedAt: j['shippedAt'] != null ? DateTime.tryParse(j['shippedAt'] as String) : null,
    );
  }
}
