import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/return_request.dart';
import '../../bloc/returns/returns_bloc.dart';
import '../../widgets/common/admin_drawer.dart';

List<Widget> _adminReturnReadOnlySections(
  BuildContext ctx,
  AdminReturnRequest r,
  NumberFormat inr,
  DateFormat dt,
) {
  final tt = Theme.of(ctx).textTheme;
  final cs = Theme.of(ctx).colorScheme;
  final lines = <Widget>[];

  void gap([double h = 10]) => lines.add(SizedBox(height: h));

  lines.add(Text(
    'Linked order',
    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
  ));
  if (r.orderStatus.isNotEmpty) {
    lines.add(Text(
      'Status: ${r.orderStatus} · Payment: ${r.orderPaymentStatus}',
      style: tt.bodySmall,
    ));
    if (r.orderTotalAmount > 0) {
      lines.add(Text(
        'Order total: ${inr.format(r.orderTotalAmount)}',
        style: tt.bodySmall,
      ));
    }
  }
  lines.add(SelectableText(
    'Order ID: ${r.orderId}',
    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
  ));
  if (r.orderCancelReason.isNotEmpty) {
    lines.add(Text(
      'Order cancel reason: ${r.orderCancelReason}',
      style: tt.bodySmall?.copyWith(color: cs.error),
    ));
  }
  if (r.orderCancelledAt != null) {
    lines.add(Text(
      'Order cancelled at: ${dt.format(r.orderCancelledAt!.toLocal())}',
      style: tt.bodySmall,
    ));
  }
  if (r.orderRefundStatus.isNotEmpty || r.orderRefundAmount != null) {
    lines.add(Text(
      'Order refund: ${r.orderRefundStatus.isEmpty ? '—' : r.orderRefundStatus}'
      '${r.orderRefundAmount != null ? ' · ${inr.format(r.orderRefundAmount!)}' : ''}',
      style: tt.bodySmall,
    ));
  }
  gap();

  lines.add(Text(
    'Items in this return',
    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
  ));
  if (r.items.isEmpty) {
    lines.add(Text('—', style: tt.bodySmall));
  } else {
    for (final it in r.items) {
      final key = it.orderItemId != null
          ? 'line …${it.orderItemId!.length > 6 ? it.orderItemId!.substring(it.orderItemId!.length - 6) : it.orderItemId!}'
          : 'index ${it.itemIndex ?? 0}';
      lines.add(Text('· $key × ${it.quantity}', style: tt.bodySmall));
    }
  }
  gap();

  if (r.type == 'exchange' &&
      (r.exchangeSize.isNotEmpty || r.exchangeColor.isNotEmpty)) {
    lines.add(Text(
      'Exchange wanted',
      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ));
    lines.add(Text(
      'Size: ${r.exchangeSize.isEmpty ? '—' : r.exchangeSize} · Colour: ${r.exchangeColor.isEmpty ? '—' : r.exchangeColor}',
      style: tt.bodySmall,
    ));
    gap();
  }

  lines.add(Text(
    'Customer reason & proof',
    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
  ));
  lines.add(Text(r.reason, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)));
  if (r.reasonDetail.isNotEmpty) {
    lines.add(const SizedBox(height: 4));
    lines.add(SelectableText(r.reasonDetail, style: tt.bodySmall));
  }
  if (r.videoUrl.isNotEmpty) {
    lines.add(const SizedBox(height: 6));
    lines.add(Text('Proof video (stored URL)', style: tt.labelMedium));
    lines.add(SelectableText(
      r.videoUrl,
      style: tt.bodySmall?.copyWith(color: cs.primary),
    ));
  } else {
    lines.add(Text('No video URL on record', style: tt.bodySmall?.copyWith(color: cs.outline)));
  }

  lines.add(const SizedBox(height: 8));
  lines.add(Text(
    'Return created: ${dt.format(r.createdAt.toLocal())}'
    '${r.updatedAt != null ? ' · Updated: ${dt.format(r.updatedAt!.toLocal())}' : ''}'
    '${r.pickupScheduledAt != null ? ' · Pickup scheduled: ${dt.format(r.pickupScheduledAt!.toLocal())}' : ''}',
    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
  ));

  return lines;
}

class AdminReturnsPage extends StatelessWidget {
  const AdminReturnsPage({super.key});

  static const statusChoices = [
    'requested',
    'approved',
    'rejected',
    'cancelled',
    'pickup_scheduled',
    'in_transit',
    'received',
    'refund_processing',
    'refunded',
    'exchange_processing',
    'exchange_shipped',
    'completed',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminReturnsBloc>()..add(AdminReturnsLoadRequested()),
      child: const _ReturnsAdminView(),
    );
  }
}

class _ReturnsAdminView extends StatelessWidget {
  const _ReturnsAdminView();

  Future<void> _edit(BuildContext context, AdminReturnRequest r) async {
    final noteCtrl = TextEditingController(text: r.adminNote);
    final rejectCtrl = TextEditingController(text: r.rejectReason);
    final courierCtrl = TextEditingController(text: r.pickupCourier);
    final awbCtrl = TextEditingController(text: r.pickupAwb);
    final exchangeAwbCtrl = TextEditingController(text: r.exchangeAwb);
    final refundCtrl = TextEditingController(
      text: r.refundAmount != null ? r.refundAmount!.toString() : '',
    );
    String status = AdminReturnsPage.statusChoices.contains(r.status)
        ? r.status
        : 'requested';

    final inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dt = DateFormat('dd MMM yyyy, HH:mm');

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: Text('Return ${r.id.length > 6 ? r.id.substring(r.id.length - 6) : r.id}'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${r.userName} · ${r.userEmail}',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    SelectableText(
                      'Return ID: ${r.id}',
                      style: Theme.of(ctx).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const Divider(height: 24),
                    ..._adminReturnReadOnlySections(ctx, r, inr, dt),
                    const Divider(height: 24),
                    Text(
                      'Workflow',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: AdminReturnsPage.statusChoices
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.replaceAll('_', ' ')),
                              ))
                          .toList(),
                      onChanged: (v) => setSt(() => status = v ?? status),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(labelText: 'Admin note'),
                      maxLines: 2,
                    ),
                    TextField(
                      controller: rejectCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reject reason (if rejected)',
                      ),
                    ),
                    TextField(
                      controller: courierCtrl,
                      decoration: const InputDecoration(labelText: 'Pickup courier'),
                    ),
                    TextField(
                      controller: awbCtrl,
                      decoration: const InputDecoration(labelText: 'Pickup AWB / tracking'),
                    ),
                    TextField(
                      controller: exchangeAwbCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Replacement shipment AWB',
                      ),
                    ),
                    TextField(
                      controller: refundCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Refund amount (₹, optional)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              FilledButton(
                onPressed: () {
                  final body = <String, dynamic>{
                    'status': status,
                    'adminNote': noteCtrl.text.trim(),
                    'rejectReason': rejectCtrl.text.trim(),
                    'pickupCourier': courierCtrl.text.trim(),
                    'pickupAwb': awbCtrl.text.trim(),
                    'exchangeAwb': exchangeAwbCtrl.text.trim(),
                  };
                  final ra = double.tryParse(refundCtrl.text.trim());
                  if (ra != null) body['refundAmount'] = ra;
                  context.read<AdminReturnsBloc>().add(AdminReturnUpdateRequested(r.id, body));
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    noteCtrl.dispose();
    rejectCtrl.dispose();
    courierCtrl.dispose();
    awbCtrl.dispose();
    exchangeAwbCtrl.dispose();
    refundCtrl.dispose();
  }

  (Color bg, Color fg) _style(String status, ColorScheme cs) {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
    final inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Returns & exchanges'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<AdminReturnsBloc>().add(AdminReturnsLoadRequested()),
          ),
        ],
      ),
      body: BlocConsumer<AdminReturnsBloc, AdminReturnsState>(
        listener: (context, state) {
          if (state is AdminReturnSaveSuccess) {
            context.read<AdminReturnsBloc>().add(AdminReturnsLoadRequested());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Updated')),
            );
          } else if (state is AdminReturnsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: cs.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminReturnsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminReturnsFailure && state.message.contains('Exception')) {
            return Center(child: Text(state.message));
          }
          final list = state is AdminReturnsLoaded ? state.returns : <AdminReturnRequest>[];
          if (list.isEmpty) {
            return Center(
              child: Text(
                'No return requests yet.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = list[i];
              final (chipBg, chipFg) = _style(r.status, cs);
              return Card(
                color: cs.surface,
                child: ListTile(
                  title: Text(
                    '${r.type == 'exchange' ? 'Exchange' : 'Return'} · ${r.userName}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (r.orderStatus.isNotEmpty)
                        Text(
                          'Order: ${r.orderStatus} · ${r.orderPaymentStatus}'
                          '${r.orderTotalAmount > 0 ? ' · ${inr.format(r.orderTotalAmount)}' : ''}',
                          style: tt.bodySmall,
                        ),
                      if (r.orderCancelReason.isNotEmpty)
                        Text(
                          'Order cancelled: ${r.orderCancelReason}',
                          style: tt.bodySmall?.copyWith(color: cs.error),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        '${r.type == 'exchange' ? 'Exchange' : 'Return'} · ${r.reason}'
                        '${r.videoUrl.isEmpty ? '' : ' · video'} · …${r.orderId.length > 6 ? r.orderId.substring(r.orderId.length - 6) : r.orderId}',
                        style: tt.bodySmall,
                      ),
                      if (r.reasonDetail.isNotEmpty)
                        Text(
                          r.reasonDetail,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (r.items.isNotEmpty)
                        Text(
                          r.items.map((e) {
                            final k = e.orderItemId != null
                                ? '…${e.orderItemId!.length > 4 ? e.orderItemId!.substring(e.orderItemId!.length - 4) : e.orderItemId!}'
                                : 'i${e.itemIndex ?? 0}';
                            return '${e.quantity}×$k';
                          }).join(', '),
                          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      if (r.pickupAwb.isNotEmpty)
                        Text(
                          'Pickup: ${r.pickupCourier.isNotEmpty ? '${r.pickupCourier} · ' : ''}${r.pickupAwb}',
                          style: tt.bodySmall,
                        ),
                      Text(
                        dateFmt.format(r.createdAt.toLocal()),
                        style: tt.labelSmall?.copyWith(color: cs.outline),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      r.status.replaceAll('_', ' '),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: chipFg,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  onTap: () => _edit(context, r),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
