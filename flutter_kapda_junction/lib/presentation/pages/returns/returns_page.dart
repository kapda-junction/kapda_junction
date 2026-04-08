import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/return_request.dart';
import '../../bloc/returns/returns_bloc.dart';

class ReturnsPage extends StatelessWidget {
  const ReturnsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReturnsBloc>()..add(const ReturnsLoadRequested()),
      child: const _ReturnsView(),
    );
  }
}

class _ReturnsView extends StatelessWidget {
  const _ReturnsView();

  static String _statusLabel(String status) {
    if (status == 'requested') return 'Pending admin approval';
    return status.replaceAll('_', ' ');
  }

  static (Color bg, Color fg) _statusStyle(String status, ColorScheme cs) {
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
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Returns & exchanges'),
      ),
      body: BlocBuilder<ReturnsBloc, ReturnsState>(
        builder: (context, state) {
          if (state is ReturnsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReturnsFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          context.read<ReturnsBloc>().add(const ReturnsLoadRequested()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is ReturnsLoaded && !state.returnsEnabled) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block, size: 48, color: cs.outline),
                    const SizedBox(height: 12),
                    Text(
                      'Returns & exchanges are turned off',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please contact support or WhatsApp the store for help.',
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final list = state is ReturnsLoaded ? state.returns : <ReturnRequest>[];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_return_outlined, size: 56, color: cs.outline),
                    const SizedBox(height: 12),
                    Text('No return requests yet', style: tt.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Open a delivered order to start a return or size exchange.',
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/orders'),
                      child: const Text('My orders'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ReturnsBloc>().add(const ReturnsLoadRequested());
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final r = list[i];
                final (bg, fg) = _statusStyle(r.status, cs);
                return Card(
                  color: cs.surface,
                  child: InkWell(
                    onTap: () => context.go('/orders/${r.orderId}'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${r.type == 'exchange' ? 'Exchange' : 'Return'} · Order …${r.orderId.length > 6 ? r.orderId.substring(r.orderId.length - 6) : r.orderId}',
                                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _statusLabel(r.status),
                                  style: tt.labelSmall?.copyWith(
                                    color: fg,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            r.reason,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          if (r.pickupAwb.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Pickup: ${r.pickupCourier.isNotEmpty ? '${r.pickupCourier} · ' : ''}${r.pickupAwb}',
                              style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                          if (r.exchangeAwb.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Replacement AWB: ${r.exchangeAwb}',
                              style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            dateFmt.format(r.createdAt),
                            style: tt.labelSmall?.copyWith(color: cs.outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
