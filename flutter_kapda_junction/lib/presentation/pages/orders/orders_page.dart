import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../bloc/orders/orders_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../domain/entities/order.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrdersBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<OrdersBloc>()..add(OrdersLoadRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  static _StatusStyle _statusStyle(OrderStatus s) => switch (s) {
        OrderStatus.delivered =>
          _StatusStyle(const Color(0xFF16A34A), const Color(0xFFDCFCE7), 'Delivered'),
        OrderStatus.cancelled =>
          _StatusStyle(const Color(0xFFDC2626), const Color(0xFFFEE2E2), 'Cancelled'),
        OrderStatus.shipped =>
          _StatusStyle(const Color(0xFF2563EB), const Color(0xFFDBEAFE), 'Shipped'),
        OrderStatus.confirmed =>
          _StatusStyle(const Color(0xFFD97706), const Color(0xFFFEF3C7), 'Confirmed'),
        OrderStatus.pending =>
          _StatusStyle(const Color(0xFF6B7280), const Color(0xFFF3F4F6), 'Placed'),
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text('My Orders',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (context, state) {
            if (state is OrdersLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OrdersFailure) {
              return Center(child: Text(state.message));
            }
            if (state is OrdersLoaded) {
              if (state.orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long_outlined,
                            size: 48, color: AppColors.accent),
                      ),
                      const SizedBox(height: 20),
                      Text('No orders yet',
                          style: tt.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Your placed orders will appear here',
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => context.go('/products'),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: const Text('Start Shopping'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _bloc.add(OrdersLoadRequested()),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: state.orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final order = state.orders[i];
                    final style = _statusStyle(order.status);
                    final shortId = order.id
                        .substring(order.id.length - 8)
                        .toUpperCase();
                    final firstItem =
                        order.items.isNotEmpty ? order.items.first : null;
                    final extraCount = order.items.length - 1;

                    return GestureDetector(
                      onTap: () => context.push('/orders/${order.id}'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(12),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // ── Top row: ID + status ──────────────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                              child: Row(
                                children: [
                                  Text(
                                    'Order #$shortId',
                                    style: tt.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: style.bg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      style.label,
                                      style: TextStyle(
                                        color: style.fg,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(height: 1, indent: 14, endIndent: 14),

                            // ── Product preview ───────────────────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              child: Row(
                                children: [
                                  // Product thumbnail
                                  if (firstItem != null)
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: const Color(0xFFF1F5F9),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: firstItem.image != null &&
                                              firstItem.image!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: firstItem.image!,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, _) =>
                                                  const Icon(Icons.checkroom,
                                                      color: Color(0xFFCBD5E1),
                                                      size: 32),
                                            )
                                          : const Icon(Icons.checkroom,
                                              color: Color(0xFFCBD5E1),
                                              size: 32),
                                    ),

                                  const SizedBox(width: 12),

                                  // Item info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (firstItem != null)
                                          Text(
                                            firstItem.name,
                                            style: tt.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        if (extraCount > 0) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '+ $extraCount more item${extraCount > 1 ? 's' : ''}',
                                            style: tt.bodySmall?.copyWith(
                                                color: cs.onSurfaceVariant),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          DateFormat('d MMM yyyy')
                                              .format(order.createdAt),
                                          style: tt.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Price + chevron
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        PriceFormatter.format(order.totalAmount),
                                        style: tt.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Icon(Icons.chevron_right_rounded,
                                          color: cs.onSurfaceVariant, size: 20),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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

class _StatusStyle {
  final Color fg;
  final Color bg;
  final String label;
  const _StatusStyle(this.fg, this.bg, this.label);
}
