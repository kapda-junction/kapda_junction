import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../../data/datasources/remote/order_datasource.dart';
import '../../../domain/entities/order.dart';
import '../../bloc/orders/orders_bloc.dart';
import '../../widgets/common/admin_drawer.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrdersBloc>()..add(const OrdersLoadRequested()),
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatefulWidget {
  const _OrdersView();
  @override
  State<_OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<_OrdersView> {
  String? _filter;

  static const _statuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
  static const _statusColors = {
    'pending': Colors.orange,
    'confirmed': Colors.blue,
    'shipped': Colors.purple,
    'delivered': Colors.green,
    'cancelled': Colors.red,
  };

  Future<void> _reloadOrders() async {
    context.read<OrdersBloc>().add(
          _filter == null
              ? const OrdersLoadRequested()
              : OrdersLoadRequested(status: _filter),
        );
  }

  Future<void> _openOrderAdmin(BuildContext context, AdminOrder o) async {
    final ds = sl<OrderDataSource>();
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final carrier = TextEditingController(text: o.shippingCarrier);
    final awb = TextEditingController(text: o.shippingAwb);
    final urlOverride = TextEditingController(text: o.shippingTrackingUrlOverride);
    final refundNoteCtrl = TextEditingController(text: o.refundNote ?? '');
    String status = o.status;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            title: Text(
              'Order #${o.id.length > 8 ? o.id.substring(o.id.length - 8) : o.id}',
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${o.userName} · ${o.userEmail}',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text('${fmt.format(o.totalAmount)} · Payment: ${o.paymentStatus}'),
                    const Divider(height: 24),
                    Text(
                      'Status',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Order status'),
                      items: _statuses
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s[0].toUpperCase() + s.substring(1)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setSt(() => status = v ?? status),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Shipment (India Post / manual)',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter article number when you ship. Customer sees a tracking link (or uses India Post website).',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: carrier,
                      decoration: const InputDecoration(
                        labelText: 'Carrier',
                        hintText: 'India Post',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: awb,
                      decoration: const InputDecoration(
                        labelText: 'Article / AWB / consignment no.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: urlOverride,
                      decoration: const InputDecoration(
                        labelText: 'Full tracking URL (optional override)',
                        hintText: 'https://...',
                      ),
                    ),
                    if (o.trackingUrl != null && o.trackingUrl!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        'Preview link: ${o.trackingUrl}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    Text(
                      'Refund audit',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Payment id: ${o.razorpayPaymentId ?? '—'}',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    Text(
                      'Refund id: ${o.razorpayRefundId ?? '—'}',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    Text(
                      'Refund status: ${o.refundStatus ?? '—'}',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    if (o.refundLastError != null &&
                        o.refundLastError!.trim().isNotEmpty)
                      Text(
                        'Last error: ${o.refundLastError}',
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: refundNoteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Internal refund note (admin)',
                      ),
                    ),
                    if (o.refundStatus == 'failed' &&
                        (o.razorpayPaymentId ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await ds.retryRefund(o.id);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) await _reloadOrders();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Refund re-initiated'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Razorpay refund'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () async {
                  try {
                    await ds.updateOrderFields(o.id, {
                      'status': status,
                      'shippingCarrier': carrier.text.trim(),
                      'shippingAwb': awb.text.trim(),
                      'shippingTrackingUrlOverride': urlOverride.text.trim(),
                      'refundNote': refundNoteCtrl.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) await _reloadOrders();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    carrier.dispose();
    awb.dispose();
    urlOverride.dispose();
    refundNoteCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(children: [
              FilterChip(
                label: const Text('All'),
                selected: _filter == null,
                onSelected: (_) {
                  setState(() => _filter = null);
                  context.read<OrdersBloc>().add(const OrdersLoadRequested());
                },
              ),
              const SizedBox(width: 8),
              ..._statuses.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s[0].toUpperCase() + s.substring(1)),
                      selected: _filter == s,
                      onSelected: (_) {
                        setState(() => _filter = s);
                        context.read<OrdersBloc>().add(OrdersLoadRequested(status: s));
                      },
                    ),
                  )),
            ]),
          ),
        ),
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OrdersFailure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<OrdersBloc>().add(
                          _filter == null
                              ? const OrdersLoadRequested()
                              : OrdersLoadRequested(status: _filter),
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is OrdersLoaded) {
            if (state.orders.isEmpty) {
              return const Center(child: Text('No orders found.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: state.orders.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final o = state.orders[i];
                final color = _statusColors[o.status] ?? Colors.grey;
                return ListTile(
                  onTap: () => _openOrderAdmin(context, o),
                  title: Text(
                    'Order #${o.id.length > 8 ? o.id.substring(o.id.length - 8) : o.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${o.items.length} item(s) · ${fmt.format(o.totalAmount)}'),
                      if (o.shippingAwb.isNotEmpty)
                        Text(
                          'AWB: ${o.shippingAwb} · ${o.shippingCarrier}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (o.createdAt != null)
                        Text(
                          dateFmt.format(o.createdAt!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (o.cancelReason != null && o.cancelReason!.trim().isNotEmpty)
                        Text(
                          'Cancel reason: ${o.cancelReason}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (o.status == 'cancelled' &&
                          (o.refundStatus != null || o.refundAmount != null))
                        Text(
                          'Refund: ${o.refundStatus ?? '—'}'
                          '${o.refundAmount != null ? ' · ${fmt.format(o.refundAmount!)}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (o.refundLastError != null &&
                          o.refundLastError!.trim().isNotEmpty)
                        Text(
                          'Refund error: ${o.refundLastError}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      o.status[0].toUpperCase() + o.status.substring(1),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
