import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../bloc/orders/orders_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/error/app_error_handler.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../data/datasources/remote/home_remote_datasource.dart';
import '../../../data/datasources/remote/order_remote_datasource.dart';
import '../../../data/datasources/remote/review_remote_datasource.dart';
import '../../../data/datasources/remote/return_remote_datasource.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/return_request.dart';

(Color bg, Color fg) _orderStatusChipColors(OrderStatus s, ColorScheme cs) {
  switch (s) {
    case OrderStatus.cancelled:
      return (cs.errorContainer, cs.onErrorContainer);
    case OrderStatus.delivered:
      return (cs.primary.withAlpha(46), cs.primary);
    case OrderStatus.shipped:
      return (cs.secondary.withAlpha(42), cs.secondary);
    case OrderStatus.confirmed:
      return (cs.secondary.withAlpha(28), cs.secondary);
    case OrderStatus.pending:
      return (cs.surfaceContainerHighest, cs.onSurfaceVariant);
  }
}

(Color bg, Color fg) _returnStatusStyle(String status, ColorScheme cs) {
  switch (status) {
    case 'rejected':
    case 'cancelled':
      return (cs.errorContainer, cs.onErrorContainer);
    case 'refunded':
    case 'completed':
      return (cs.primary.withAlpha(46), cs.primary);
    case 'requested':
      return (cs.secondary.withAlpha(40), cs.secondary);
    default:
      return (cs.surfaceContainerHighest, cs.onSurfaceVariant);
  }
}

String _returnStatusDisplay(String status) {
  if (status == 'requested') return 'Pending admin approval';
  return status.replaceAll('_', ' ');
}

String _returnTypeChipLabel(String type) {
  switch (type) {
    case 'exchange':
      return 'Exchange';
    case 'order_cancel':
      return 'Cancel order';
    default:
      return 'Return';
  }
}

bool _hasPendingOrderCancel(List<ReturnRequest>? list) {
  if (list == null) return false;
  for (final r in list) {
    if (r.type == 'order_cancel' && r.status == 'requested') return true;
  }
  return false;
}

// Active = any return/exchange NOT in a terminal state
const _terminalReturnStatuses = {
  'rejected', 'cancelled', 'refunded', 'completed'
};

bool _hasActiveReturn(List<ReturnRequest>? list) {
  if (list == null || list.isEmpty) return false;
  return list.any(
    (r) => r.type != 'order_cancel' && !_terminalReturnStatuses.contains(r.status),
  );
}

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final OrdersBloc _bloc;
  List<ReturnRequest>? _returns;
  bool _returnsLoading = false;
  bool? _returnsEnabled;
  bool? _returnVideoRequired;
  bool? _customerOrderCancelEnabled;
  /// Product id → review moderation status for this order (from GET /reviews/mine).
  Map<String, String> _reviewStatusByProductId = {};

  @override
  void initState() {
    super.initState();
    _bloc = sl<OrdersBloc>()..add(OrderDetailRequested(widget.orderId));
    _loadReturns();
    _loadPolicy();
    _loadReviewedProductsForOrder();
  }

  Future<void> _loadReviewedProductsForOrder() async {
    try {
      final map = await sl<ReviewRemoteDataSource>()
          .reviewStatusByProductForOrder(widget.orderId);
      if (!mounted) return;
      setState(() => _reviewStatusByProductId = map);
    } catch (_) {
      if (mounted) setState(() => _reviewStatusByProductId = {});
    }
  }

  Future<void> _loadPolicy() async {
    try {
      final m = await sl<HomeRemoteDataSource>().getSettings();
      if (!mounted) return;
      setState(() {
        _returnsEnabled = m['returnsEnabled'] != false;
        _returnVideoRequired = m['returnVideoRequired'] != false;
        _customerOrderCancelEnabled = m['customerOrderCancelEnabled'] != false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _returnsEnabled = true;
          _returnVideoRequired = true;
          _customerOrderCancelEnabled = true;
        });
      }
    }
  }

  Future<void> _loadReturns() async {
    setState(() => _returnsLoading = true);
    try {
      final list =
          await sl<ReturnRemoteDataSource>().list(orderId: widget.orderId);
      if (mounted) {
        setState(() {
          _returns = list;
          _returnsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _returnsLoading = false);
    }
  }

  Future<void> _confirmCancelOrder(BuildContext context, Order order) async {
    if (order.isPaid) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetCtx) => _OrderCancelSheet(
          order: order,
          returnVideoRequired: _returnVideoRequired ?? true,
          onSubmitted: () {
            Navigator.pop(sheetCtx);
            _onCancelFlowCompleted(
              message:
                  'Cancellation request sent. Admin will verify your video and details before any refund.',
            );
          },
        ),
      );
      return;
    }

    final result = await showDialog<(bool, String)?>(
      context: context,
      builder: (ctx) => const _UnpaidCancelDialog(),
    );
    if (result == null || !result.$1 || !mounted) return;
    final note = result.$2.trim();
    try {
      await sl<OrderRemoteDataSource>().cancelOrderCustomer(
        order.id,
        reason: note.isEmpty ? null : note,
      );
      _onCancelFlowCompleted(message: 'Order cancelled');
    } catch (e) {
      if (!mounted) return;
      AppErrorHandler.show(e.toString());
    }
  }

  /// Defers BLoC + [setState] until after the route/dialog cleanup to avoid framework asserts.
  void _onCancelFlowCompleted({required String message}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bloc.add(OrderDetailRequested(widget.orderId));
      _loadReturns();
      AppNotification.showSuccess(context, message);
    });
  }

  Widget _reviewCtaForLineItem(
    BuildContext context,
    Order order,
    OrderItem item,
    TextTheme tt,
    ColorScheme cs,
  ) {
    final st = _reviewStatusByProductId[item.productId];
    if (st != null) {
      final (String label, Color fg) = switch (st) {
        'approved' => (
            'Review published',
            const Color(0xFF059669),
          ),
        'rejected' => (
            'Review not published',
            cs.onSurfaceVariant,
          ),
        _ => (
            'Review submitted — pending approval',
            cs.onSurfaceVariant,
          ),
      };
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return TextButton.icon(
      onPressed: () => _openReviewForItem(context, order, item),
      icon: Icon(
        Icons.rate_review_outlined,
        size: 18,
        color: cs.primary,
      ),
      label: Text(
        'Rate & review',
        style: TextStyle(color: cs.primary),
      ),
    );
  }

  Future<void> _openReviewForItem(
    BuildContext context,
    Order order,
    OrderItem item,
  ) async {
    final result = await showDialog<_ReviewDialogResult>(
      context: context,
      builder: (ctx) => _WriteReviewDialog(item: item),
    );
    if (result == null || !mounted) return;
    try {
      await sl<ReviewRemoteDataSource>().createReview(
        orderId: order.id,
        productId: item.productId,
        rating: result.rating,
        title: result.title,
        body: result.body,
      );
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _reviewStatusByProductId = {
            ..._reviewStatusByProductId,
            item.productId: 'pending',
          };
        });
        AppNotification.showSuccess(
          context,
          'Thanks! Your review will show after admin approval.',
        );
        _bloc.add(OrderDetailRequested(widget.orderId));
      });
    } catch (e) {
      if (!mounted) return;
      var msg = e.toString();
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'].toString();
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppErrorHandler.show(msg);
      });
    }
  }

  Future<void> _openReturnSheet(BuildContext context, Order order) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => _ReturnExchangeSheet(
        order: order,
        returnVideoRequired: _returnVideoRequired ?? true,
        onSubmitted: () async {
          Navigator.pop(ctx);
          await _loadReturns();
          if (context.mounted) {
            AppNotification.showSuccess(context, 'Return request submitted');
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  static String _statusLabel(OrderStatus s) => switch (s) {
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
        OrderStatus.shipped => 'Shipped',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.pending => 'Placed',
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Order Details',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        ),
        body: BlocConsumer<OrdersBloc, OrdersState>(
          listenWhen: (prev, cur) => cur is OrderDetailLoaded,
          listener: (context, state) {
            if (state is OrderDetailLoaded) {
              _loadReturns();
              _loadReviewedProductsForOrder();
            }
          },
          builder: (context, state) {
            if (state is OrdersLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OrdersFailure) {
              return Center(child: Text(state.message));
            }
            if (state is OrderDetailLoaded) {
              final order = state.order;
              final shortId = order.id
                  .substring(order.id.length - 8)
                  .toUpperCase();

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Order header card ─────────────────────────────────
                    _Card(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Order #$shortId',
                                    style: tt.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3)),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('d MMMM yyyy, h:mm a')
                                      .format(order.createdAt),
                                  style: tt.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            children: [
                              Builder(
                                builder: (ctx) {
                                  final (bg, fg) =
                                      _orderStatusChipColors(order.status, cs);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _statusLabel(order.status),
                                      style: TextStyle(
                                        color: fg,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 6),
                              // Copy full ID
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: order.id));
                                  AppNotification.showInfo(context, 'Order ID copied');
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.copy_outlined,
                                        size: 12,
                                        color: cs.onSurfaceVariant),
                                    const SizedBox(width: 3),
                                    Text('Copy ID',
                                        style: tt.labelSmall?.copyWith(
                                            color: cs.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Status timeline ───────────────────────────────────
                    if (order.status != OrderStatus.cancelled)
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order Progress',
                                style: tt.labelLarge?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            _OrderTimeline(status: order.status, cs: cs),
                          ],
                        ),
                      ),

                    if (order.status != OrderStatus.cancelled &&
                        (order.status == OrderStatus.shipped ||
                            order.status == OrderStatus.delivered) &&
                        (order.shippingAwb.isNotEmpty ||
                            (order.trackingUrl != null &&
                                order.trackingUrl!.isNotEmpty))) ...[
                      const SizedBox(height: 12),
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery tracking',
                              style: tt.labelLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We ship via India Post (or the carrier shown below). Use your article number on the India Post tracking page.',
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            if (order.shippingCarrier.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Carrier: ${order.shippingCarrier}',
                                style: tt.bodyMedium,
                              ),
                            ],
                            if (order.shippingAwb.isNotEmpty)
                              Text(
                                'Article / AWB: ${order.shippingAwb}',
                                style: tt.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            if (order.shippedAt != null)
                              Text(
                                'Marked shipped: ${DateFormat('d MMM yyyy').format(order.shippedAt!.toLocal())}',
                                style: tt.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            if (order.trackingUrl != null &&
                                order.trackingUrl!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () async {
                                  final u = Uri.parse(order.trackingUrl!);
                                  if (await canLaunchUrl(u)) {
                                    await launchUrl(u,
                                        mode: LaunchMode.externalApplication);
                                  }
                                },
                                icon: const Icon(Icons.open_in_new, size: 20),
                                label: const Text('Open tracking page'),
                              ),
                            ] else if (order.shippingAwb.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Tracking link not available — use your article number on India Post’s official track page.',
                                  style: tt.bodySmall
                                      ?.copyWith(color: cs.outline),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    if (order.status == OrderStatus.cancelled)
                      _Card(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cs.errorContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.cancel_outlined,
                                  color: cs.onErrorContainer, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Order Cancelled',
                                      style: tt.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: cs.onErrorContainer,
                                      )),
                                  Text(
                                    order.cancelReason?.isNotEmpty == true
                                        ? order.cancelReason!
                                        : 'This order has been cancelled',
                                    style: tt.bodySmall
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                  if (order.refundStatus != null &&
                                      order.refundStatus!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Refund status: ${order.refundStatus}',
                                      style: tt.bodySmall,
                                    ),
                                  ],
                                  if (order.razorpayRefundId != null &&
                                      order.razorpayRefundId!.isNotEmpty)
                                    Text(
                                      'Refund ref: ${order.razorpayRefundId}',
                                      style: tt.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  if (order.refundLastError != null &&
                                      order.refundLastError!.isNotEmpty)
                                    Text(
                                      'Note: ${order.refundLastError}',
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.error,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // ── Items ─────────────────────────────────────────────
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Items (${order.items.length})',
                            style: tt.labelLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          ...order.items.asMap().entries.map((e) {
                            final idx = e.key;
                            final item = e.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (idx > 0) ...[
                                  Divider(
                                      color: cs.outlineVariant.withAlpha(80),
                                      height: 20),
                                ],
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product image
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: cs.surfaceContainerHighest,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: item.image != null &&
                                              item.image!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: item.image!,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, _, _) => Icon(
                                                  Icons.checkroom,
                                                  color: cs.outline,
                                                  size: 32),
                                            )
                                          : Icon(Icons.checkroom,
                                              color: cs.outline, size: 32),
                                    ),
                                    const SizedBox(width: 12),
                                    // Item details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: tt.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                height: 1.3),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            children: [
                                              if (item.color != null)
                                                _Chip(item.color!),
                                              if (item.size != null)
                                                _Chip(item.size!),
                                              _Chip('Qty: ${item.quantity}'),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            PriceFormatter.format(item.price),
                                            style: tt.bodySmall?.copyWith(
                                                color: cs.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Subtotal
                                    Text(
                                      PriceFormatter.format(item.subtotal),
                                      style: tt.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                                if (order.status == OrderStatus.delivered &&
                                    order.isPaid)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: _reviewCtaForLineItem(
                                      context,
                                      order,
                                      item,
                                      tt,
                                      cs,
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Shipping address ──────────────────────────────────
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: cs.secondary.withAlpha(28),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                    Icons.location_on_outlined,
                                    size: 17,
                                    color: cs.secondary),
                              ),
                              const SizedBox(width: 10),
                              Text('Shipping Address',
                                  style: tt.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            order.shippingAddress.name,
                            style: tt.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.shippingAddress.address,
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          Text(
                            '${order.shippingAddress.city}, ${order.shippingAddress.state} - ${order.shippingAddress.pincode}',
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined,
                                  size: 14, color: cs.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text(
                                order.shippingAddress.phone,
                                style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Payment summary ───────────────────────────────────
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: cs.secondary.withAlpha(28),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 17,
                                    color: cs.secondary),
                              ),
                              const SizedBox(width: 10),
                              Text('Payment',
                                  style: tt.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: order.isPaid
                                      ? cs.primary.withAlpha(40)
                                      : cs.errorContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.paymentStatus.name
                                      .replaceAllMapped(
                                        RegExp(r'([A-Z])'),
                                        (m) => ' ${m[0]}',
                                      )
                                      .trim()
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: order.isPaid
                                        ? cs.primary
                                        : cs.onErrorContainer,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(
                              color: cs.outlineVariant.withAlpha(80),
                              height: 1),
                          const SizedBox(height: 14),
                          if (order.discountAmount > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Subtotal',
                                    style: tt.bodyMedium?.copyWith(
                                        color: cs.onSurfaceVariant)),
                                Text(PriceFormatter.format(order.subtotal),
                                    style: tt.bodyMedium),
                              ],
                            ),
                            if (order.couponCode.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Coupon (${order.couponCode})',
                                      style: tt.bodyMedium?.copyWith(
                                          color: cs.onSurfaceVariant),
                                    ),
                                    Text(
                                      '− ${PriceFormatter.format(order.discountAmount)}',
                                      style: tt.bodyMedium?.copyWith(
                                        color: cs.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Discount',
                                        style: tt.bodyMedium?.copyWith(
                                            color: cs.onSurfaceVariant)),
                                    Text(
                                      '− ${PriceFormatter.format(order.discountAmount)}',
                                      style: tt.bodyMedium?.copyWith(
                                        color: cs.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 10),
                          ],
                          // Order total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order Total',
                                  style: tt.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800)),
                              Text(
                                PriceFormatter.format(order.totalAmount),
                                  style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (order.status == OrderStatus.delivered &&
                        order.isPaid) ...[
                      const SizedBox(height: 12),
                      if (!(_returnsEnabled ?? true))
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline,
                                      color: cs.onSurfaceVariant, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Returns and exchanges are currently turned off.',
                                      style: tt.bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Contact support if you need help with this order.',
                                style: tt.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        )
                      else
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Returns & exchanges',
                                style: tt.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_returnsLoading)
                                const LinearProgressIndicator(minHeight: 2)
                              else if (_returns != null &&
                                  _returns!.isNotEmpty) ...[
                                ..._returns!.map((r) {
                                  final (_, rf) =
                                      _returnStatusStyle(r.status, cs);
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: Material(
                                      color: cs.surfaceContainerHighest
                                          .withAlpha(60),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Chip(
                                                  label: Text(
                                                    _returnTypeChipLabel(r.type),
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  padding: EdgeInsets.zero,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _returnStatusDisplay(
                                                        r.status),
                                                    style: tt.labelMedium
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: rf,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (r.pickupAwb.isNotEmpty)
                                              Text(
                                                'Pickup: ${r.pickupCourier.isNotEmpty ? '${r.pickupCourier} · ' : ''}${r.pickupAwb}',
                                                style: tt.bodySmall,
                                              ),
                                            if (r.exchangeAwb.isNotEmpty)
                                              Text(
                                                'Replacement: ${r.exchangeAwb}',
                                                style: tt.bodySmall,
                                              ),
                                            if (r.rejectReason.isNotEmpty)
                                              Text(
                                                'Note: ${r.rejectReason}',
                                                style: tt.bodySmall?.copyWith(
                                                  color: cs.error,
                                                ),
                                              ),
                                            if (r.status == 'requested')
                                              TextButton(
                                                onPressed: () async {
                                                  try {
                                                    await sl<
                                                            ReturnRemoteDataSource>()
                                                        .cancelReturn(r.id);
                                                    await _loadReturns();
                                                    if (context.mounted) {
                                                      AppNotification.showSuccess(
                                                        context,
                                                        'Request cancelled',
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      AppErrorHandler.show(e.toString());
                                                    }
                                                  }
                                                },
                                                child: const Text(
                                                    'Cancel request'),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ] else
                                Text(
                                  'Eligible for return or size exchange. Requests need admin approval before pickup or refund.',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (!_hasActiveReturn(_returns))
                                FilledButton.icon(
                                  onPressed: () =>
                                      _openReturnSheet(context, order),
                                  icon: const Icon(
                                      Icons.assignment_return_outlined,
                                      size: 20),
                                  label:
                                      const Text('Start return or exchange'),
                                ),
                            ],
                          ),
                        ),
                    ],

                    if ((order.status == OrderStatus.pending ||
                            order.status == OrderStatus.confirmed) &&
                        !order.isCancelled) ...[
                      const SizedBox(height: 12),
                      if (_hasPendingOrderCancel(_returns))
                        _Card(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.hourglass_top_outlined,
                                  color: cs.secondary, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Cancellation request sent. An admin will review your proof video and reason before any refund is started.',
                                  style: tt.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (!(_customerOrderCancelEnabled ?? true))
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cancel order',
                                style: tt.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Self-service cancellation is not available. Please contact support.',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cancel order',
                                style: tt.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                order.isPaid
                                    ? 'We will send a cancellation request to our team. A Razorpay refund is started only after an admin approves your video and details.'
                                    : 'You can cancel before this order is shipped.',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => _confirmCancelOrder(
                                  context,
                                  order,
                                ),
                                icon: Icon(Icons.cancel_outlined,
                                    color: cs.error),
                                label: Text(
                                  'Cancel this order',
                                  style: TextStyle(color: cs.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _ReviewDialogResult {
  final int rating;
  final String title;
  final String body;
  const _ReviewDialogResult({
    required this.rating,
    required this.title,
    required this.body,
  });
}

class _WriteReviewDialog extends StatefulWidget {
  final OrderItem item;
  const _WriteReviewDialog({required this.item});

  @override
  State<_WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<_WriteReviewDialog> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  double _rating = 5;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final r = _rating.round();
    return AlertDialog(
      title: const Text('Write a review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.item.name, style: tt.titleSmall),
            const SizedBox(height: 12),
            Text('Rating: $r / 5'),
            Slider(
              value: _rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: '$r',
              onChanged: (v) => setState(() => _rating = v),
            ),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Your experience (optional)',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reviews are checked before they appear on the product page.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ReviewDialogResult(
              rating: r,
              title: _titleCtrl.text,
              body: _bodyCtrl.text,
            ),
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _UnpaidCancelDialog extends StatefulWidget {
  const _UnpaidCancelDialog();

  @override
  State<_UnpaidCancelDialog> createState() => _UnpaidCancelDialogState();
}

class _UnpaidCancelDialogState extends State<_UnpaidCancelDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel order?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This order will be marked as cancelled.'),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(labelText: 'Reason (optional)'),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep order'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, (true, _reasonCtrl.text.trim())),
          child: const Text('Cancel order'),
        ),
      ],
    );
  }
}

/// Paid orders: min. detail + proof video (when policy requires), then API creates admin review request.
class _OrderCancelSheet extends StatefulWidget {
  final Order order;
  final VoidCallback onSubmitted;
  final bool returnVideoRequired;

  const _OrderCancelSheet({
    required this.order,
    required this.onSubmitted,
    required this.returnVideoRequired,
  });

  @override
  State<_OrderCancelSheet> createState() => _OrderCancelSheetState();
}

class _OrderCancelSheetState extends State<_OrderCancelSheet> {
  final _detailCtrl = TextEditingController();
  bool _saving = false;
  String? _videoUrl;
  bool _uploadingVideo = false;

  @override
  void dispose() {
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadVideo(ImageSource source) async {
    final x = await ImagePicker().pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 90),
    );
    if (x == null || !mounted) return;
    setState(() => _uploadingVideo = true);
    try {
      final url = await sl<ApiClient>().uploadReturnVideo(x.path);
      if (!mounted) return;
      setState(() {
        _videoUrl = url;
        _uploadingVideo = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingVideo = false);
        AppErrorHandler.show(e.toString(), title: 'Upload Failed');
      }
    }
  }

  Future<void> _submit() async {
    final d = _detailCtrl.text.trim();
    if (d.length < 10) {
      AppErrorHandler.show(
        'Please explain why you want to cancel (at least 10 characters)',
        title: 'Description Required',
      );
      return;
    }
    if (widget.returnVideoRequired &&
        (_videoUrl == null || _videoUrl!.trim().isEmpty)) {
      AppErrorHandler.show(
        'Please upload a short proof video',
        title: 'Video Required',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await sl<OrderRemoteDataSource>().cancelOrderCustomer(
        widget.order.id,
        reason: d,
        videoUrl: _videoUrl?.trim().isNotEmpty == true ? _videoUrl!.trim() : null,
      );
      widget.onSubmitted();
    } catch (e) {
      if (mounted) AppErrorHandler.show(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Request order cancellation',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Your reason and video go to the team for review. Razorpay refund runs only after approval.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detailCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Why do you want to cancel? (min. 10 characters)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Proof video',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              widget.returnVideoRequired
                  ? 'Required — short clip as proof (same as returns).'
                  : 'Optional — upload if you can.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _uploadingVideo
                      ? null
                      : () => _pickAndUploadVideo(ImageSource.camera),
                  icon: _uploadingVideo
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onSurfaceVariant,
                          ),
                        )
                      : const Icon(Icons.videocam_outlined, size: 20),
                  label: Text(_uploadingVideo ? 'Uploading…' : 'Record'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _uploadingVideo
                      ? null
                      : () => _pickAndUploadVideo(ImageSource.gallery),
                  icon: const Icon(Icons.video_library_outlined, size: 20),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            if (_videoUrl != null && _videoUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Uploaded',
                style: tt.labelMedium?.copyWith(color: cs.primary),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit cancellation request'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Return / exchange bottom sheet ───────────────────────────────────────────
class _ReturnExchangeSheet extends StatefulWidget {
  final Order order;
  final Future<void> Function() onSubmitted;
  final bool returnVideoRequired;

  const _ReturnExchangeSheet({
    required this.order,
    required this.onSubmitted,
    required this.returnVideoRequired,
  });

  @override
  State<_ReturnExchangeSheet> createState() => _ReturnExchangeSheetState();
}

class _ReturnExchangeSheetState extends State<_ReturnExchangeSheet> {
  late String _type;
  final Map<int, int> _qtyByIndex = {};
  String _reasonKey = 'wrong_size';
  final _detailCtrl = TextEditingController();
  final _exSizeCtrl = TextEditingController();
  final _exColorCtrl = TextEditingController();
  bool _saving = false;
  String? _videoUrl;
  bool _uploadingVideo = false;

  static const _reasons = <(String, String)>[
    ('wrong_size', 'Wrong size / does not fit'),
    ('defective', 'Defective or damaged'),
    ('not_as_described', 'Not as described'),
    ('changed_mind', 'Changed my mind'),
    ('other', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    _type = 'return';
  }

  @override
  void dispose() {
    _detailCtrl.dispose();
    _exSizeCtrl.dispose();
    _exColorCtrl.dispose();
    super.dispose();
  }

  String get _reasonLabel =>
      _reasons.firstWhere((e) => e.$1 == _reasonKey, orElse: () => _reasons.last).$2;

  Future<void> _pickAndUploadVideo(ImageSource source) async {
    final x = await ImagePicker().pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 90),
    );
    if (x == null) return;
    if (!mounted) return;
    setState(() => _uploadingVideo = true);
    try {
      // Server uploads to Cloudinary and returns https URL — we store that URL on the return request.
      final url = await sl<ApiClient>().uploadReturnVideo(x.path);
      if (!mounted) return;
      setState(() {
        _videoUrl = url;
        _uploadingVideo = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingVideo = false);
        AppErrorHandler.show(e.toString(), title: 'Upload Failed');
      }
    }
  }

  Future<void> _submit() async {
    final bodyItems = <Map<String, dynamic>>[];
    for (var i = 0; i < widget.order.items.length; i++) {
      final q = _qtyByIndex[i] ?? 0;
      if (q <= 0) continue;
      final line = widget.order.items[i];
      bodyItems.add({
        if (line.lineItemId != null) 'orderItemId': line.lineItemId,
        'itemIndex': i,
        'quantity': q,
      });
    }
    if (bodyItems.isEmpty) {
      AppErrorHandler.show('Select quantities for at least one item', title: 'Select Items');
      return;
    }
    if (_detailCtrl.text.trim().length < 10) {
      AppErrorHandler.show('Please describe the issue in at least 10 characters', title: 'Description Required');
      return;
    }
    if (widget.returnVideoRequired &&
        (_videoUrl == null || _videoUrl!.trim().isEmpty)) {
      AppErrorHandler.show('Please upload a short product video as proof', title: 'Video Required');
      return;
    }
    if (_type == 'exchange' &&
        _exSizeCtrl.text.trim().isEmpty &&
        _exColorCtrl.text.trim().isEmpty) {
      AppErrorHandler.show('Enter the size or colour you want in exchange', title: 'Exchange Details Required');
      return;
    }

    setState(() => _saving = true);
    try {
      await sl<ReturnRemoteDataSource>().create({
        'orderId': widget.order.id,
        'type': _type,
        'items': bodyItems,
        'reason': _reasonLabel,
        'reasonDetail': _detailCtrl.text.trim(),
        if (_videoUrl != null && _videoUrl!.trim().isNotEmpty)
          'videoUrl': _videoUrl!.trim(),
        if (_type == 'exchange')
          'exchangeFor': {
            'size': _exSizeCtrl.text.trim(),
            'color': _exColorCtrl.text.trim(),
          },
      });
      await widget.onSubmitted();
    } catch (e) {
      if (mounted) AppErrorHandler.show(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Return or exchange',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'return',
                  label: Text('Refund'),
                  icon: Icon(Icons.payments_outlined, size: 18),
                ),
                ButtonSegment(
                  value: 'exchange',
                  label: Text('Exchange'),
                  icon: Icon(Icons.swap_horiz, size: 18),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) =>
                  setState(() => _type = s.isEmpty ? _type : s.first),
            ),
            const SizedBox(height: 16),
            Text(
              'Items from this order',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...widget.order.items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final v = _qtyByIndex[i] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: tt.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${item.color ?? '—'} · ${item.size ?? '—'} · max ${item.quantity}',
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    DropdownButton<int>(
                      value: v > 0 ? v : 0,
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(
                            '—',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                        ...List.generate(
                          item.quantity,
                          (k) => DropdownMenuItem(value: k + 1, child: Text('${k + 1}')),
                        ),
                      ],
                      onChanged: (x) {
                        setState(() {
                          if (x == null || x == 0) {
                            _qtyByIndex.remove(i);
                          } else {
                            _qtyByIndex[i] = x;
                          }
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Text('Reason', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            DropdownButtonFormField<String>(
              value: _reasonKey,
              items: _reasons
                  .map(
                    (e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _reasonKey = v ?? _reasonKey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailCtrl,
              decoration: const InputDecoration(
                labelText: 'Details (required, min. 10 characters)',
                hintText: 'Describe the issue for admin review',
              ),
              maxLines: 3,
            ),
            if (widget.returnVideoRequired) ...[
              const SizedBox(height: 14),
              Text(
                'Product video',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Maximum one video. After it uploads, you cannot change it (close this form and open again only if you have not submitted yet). Proof is stored on our server and only the link is saved with your request.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              if (_videoUrl != null && _videoUrl!.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: cs.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Video attached (1/1). Submit your request — upload options are locked.',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _uploadingVideo
                            ? null
                            : () => _pickAndUploadVideo(ImageSource.camera),
                        icon: _uploadingVideo
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.primary,
                                ),
                              )
                            : const Icon(Icons.videocam_outlined, size: 20),
                        label: Text(
                          _uploadingVideo ? 'Uploading…' : 'Record video',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _uploadingVideo
                            ? null
                            : () => _pickAndUploadVideo(ImageSource.gallery),
                        icon: const Icon(Icons.video_library_outlined, size: 20),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
            ],
            if (_type == 'exchange') ...[
              const SizedBox(height: 12),
              Text(
                'Exchange for',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _exSizeCtrl,
                decoration: const InputDecoration(labelText: 'Size'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _exColorCtrl,
                decoration: const InputDecoration(labelText: 'Colour'),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit request'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable card ─────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Small chip for color/size/qty ─────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ── Order status timeline ─────────────────────────────────────────────────────
class _OrderTimeline extends StatelessWidget {
  final OrderStatus status;
  final ColorScheme cs;
  const _OrderTimeline({required this.status, required this.cs});

  static const _steps = [
    (OrderStatus.pending, Icons.shopping_cart_outlined, 'Placed'),
    (OrderStatus.confirmed, Icons.verified_outlined, 'Confirmed'),
    (OrderStatus.shipped, Icons.local_shipping_outlined, 'Shipped'),
    (OrderStatus.delivered, Icons.home_outlined, 'Delivered'),
  ];

  int get _currentIndex => switch (status) {
        OrderStatus.pending => 0,
        OrderStatus.confirmed => 1,
        OrderStatus.shipped => 2,
        OrderStatus.delivered => 3,
        OrderStatus.cancelled => -1,
      };

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex;
    final accent = cs.secondary;
    final trackOn = cs.outline;
    final trackOff = cs.surfaceContainerHighest;
    return Row(
      children: _steps.asMap().entries.map((e) {
        final idx = e.key;
        final step = e.value;
        final isDone = idx <= current;
        final isActive = idx == current;
        final isLast = idx == _steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isActive ? 38 : 32,
                      height: isActive ? 38 : 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? accent : trackOff,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: accent.withAlpha(70),
                                  blurRadius: 10,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        step.$2,
                        size: isActive ? 18 : 15,
                        color: isDone ? cs.onSecondary : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.$3,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isDone ? accent : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                      color: idx < current ? accent : trackOn.withAlpha(80),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
