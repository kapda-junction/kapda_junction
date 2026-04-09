import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../widgets/common/admin_drawer.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  /// Bump when [DashboardLoaded] shape changes so hot reload gets a fresh bloc.
  static const Key _blocProviderKey = ValueKey<String>('dashboard_bloc_v2');

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: _blocProviderKey,
      create: (_) => sl<DashboardBloc>()..add(DashboardLoadRequested()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  static const _statusColors = {
    'pending': Color(0xFFF97316),
    'confirmed': Color(0xFF3B82F6),
    'shipped': Color(0xFF9333EA),
    'delivered': Color(0xFF059669),
    'cancelled': Color(0xFFDC2626),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: cs.error),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => context
                          .read<DashboardBloc>()
                          .add(DashboardLoadRequested()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is DashboardLoaded) {
            final fmt = NumberFormat.currency(
              locale: 'en_IN',
              symbol: '₹',
              decimalDigits: 0,
            );
            final dateStr =
                DateFormat('EEE, d MMM yyyy').format(DateTime.now());
            return RefreshIndicator(
              onRefresh: () async => context
                  .read<DashboardBloc>()
                  .add(DashboardLoadRequested()),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Store overview',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track revenue, orders, and quick actions in one place.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _RevenueHero(
                      revenueText: fmt.format(state.totalRevenue),
                      orderCount: state.totalOrders,
                      pendingCount: state.pendingOrders,
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final cols = w >= 720 ? 3 : 2;
                        final spacing = 12.0;
                        final cardW = (w - spacing * (cols - 1)) / cols;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            _MetricTile(
                              width: cardW,
                              label: 'Catalog',
                              value: '${state.totalProducts}',
                              caption: 'Products live',
                              icon: Icons.inventory_2_rounded,
                              accent: AppColors.info,
                            ),
                            _MetricTile(
                              width: cardW,
                              label: 'Orders',
                              value: '${state.totalOrders}',
                              caption: 'All time',
                              icon: Icons.receipt_long_rounded,
                              accent: const Color(0xFFEA580C),
                            ),
                            _MetricTile(
                              width: cardW,
                              label: 'Needs action',
                              value: '${state.pendingOrders}',
                              caption: 'Pending',
                              icon: Icons.schedule_rounded,
                              accent: AppColors.warning,
                            ),
                            _MetricTile(
                              width: cardW,
                              label: 'Delivered',
                              value: '${state.deliveredOrders}',
                              caption: 'Completed',
                              icon: Icons.check_circle_rounded,
                              accent: AppColors.success,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Order pipeline',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PipelineCard(
                      segments: [
                        _PipeSeg(
                          label: 'Pending',
                          count: state.pendingOrders,
                          color: _statusColors['pending']!,
                        ),
                        _PipeSeg(
                          label: 'Confirmed',
                          count: state.confirmedOrders,
                          color: _statusColors['confirmed']!,
                        ),
                        _PipeSeg(
                          label: 'Shipped',
                          count: state.shippedOrders,
                          color: _statusColors['shipped']!,
                        ),
                        _PipeSeg(
                          label: 'Done',
                          count: state.deliveredOrders,
                          color: _statusColors['delivered']!,
                        ),
                        _PipeSeg(
                          label: 'Cancelled',
                          count: state.cancelledOrders,
                          color: _statusColors['cancelled']!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            'Recent orders',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/orders'),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (state.recentOrders.isEmpty)
                      _EmptyRecentCard(theme: theme, cs: cs)
                    else
                      _RecentOrdersCard(
                        orders: state.recentOrders,
                        fmt: fmt,
                        statusColors: _statusColors,
                      ),
                    const SizedBox(height: 20),
                    _QuickContactCard(
                      whatsappNumber: state.whatsappNumber,
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _RevenueHero extends StatelessWidget {
  final String revenueText;
  final int orderCount;
  final int pendingCount;

  const _RevenueHero({
    required this.revenueText,
    required this.orderCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(55),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(36),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Total revenue',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withAlpha(230),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            revenueText,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$orderCount orders · '
            '${pendingCount == 0 ? 'No pending queue' : '$pendingCount awaiting fulfillment'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withAlpha(200),
                  height: 1.3,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;

  const _MetricTile({
    required this.width,
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withAlpha(90)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withAlpha(20),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withAlpha(28),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PipeSeg {
  final String label;
  final int count;
  final Color color;
  const _PipeSeg({
    required this.label,
    required this.count,
    required this.color,
  });
}

class _PipelineCard extends StatelessWidget {
  final List<_PipeSeg> segments;

  const _PipelineCard({required this.segments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = segments.fold<int>(0, (s, e) => s + e.count);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withAlpha(90)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              if (total == 0) {
                return SizedBox(
                  height: 8,
                  width: w,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.outline.withAlpha(55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      for (final s in segments)
                        SizedBox(
                          width: w * (s.count / total),
                          child: Container(
                            color: s.count == 0
                                ? cs.outline.withAlpha(35)
                                : s.color.withAlpha(220),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in segments)
                _PipelineChip(
                  label: s.label,
                  count: s.count,
                  dot: s.color,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            total == 0
                ? 'No orders yet — pipeline will fill as orders come in.'
                : 'Distribution across $total order${total == 1 ? '' : 's'}.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineChip extends StatelessWidget {
  final String label;
  final int count;
  final Color dot;

  const _PipelineChip({
    required this.label,
    required this.count,
    required this.dot,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersCard extends StatelessWidget {
  final List<DashboardRecentOrder> orders;
  final NumberFormat fmt;
  final Map<String, Color> statusColors;

  const _RecentOrdersCard({
    required this.orders,
    required this.fmt,
    required this.statusColors,
  });

  static String _shortId(String id) {
    final t = id.trim();
    if (t.length <= 8) return t.toUpperCase();
    return t.substring(t.length - 8).toUpperCase();
  }

  static String _statusLabel(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withAlpha(90)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < orders.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: cs.outline.withAlpha(60)),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                orders[i].customerName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '#${_shortId(orders[i].id)} · ${_relativeTime(orders[i].createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(orders[i].totalAmount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (statusColors[orders[i].status] ?? cs.outline)
                          .withAlpha(36),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(orders[i].status),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: statusColors[orders[i].status] ??
                            cs.onSurfaceVariant,
                      ),
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

  static String _relativeTime(DateTime? d) {
    if (d == null) return '—';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(d);
  }
}

class _EmptyRecentCard extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme cs;

  const _EmptyRecentCard({required this.theme, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withAlpha(90)),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: cs.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            'No orders to show',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'New orders will appear here.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickContactCard extends StatelessWidget {
  final String whatsappNumber;

  const _QuickContactCard({required this.whatsappNumber});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasNumber = whatsappNumber.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF25D366).withAlpha(28),
            cs.primary.withAlpha(20),
          ],
        ),
        border: Border.all(color: cs.outline.withAlpha(80)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.go('/settings'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withAlpha(80),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.chat_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WhatsApp inquiry',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasNumber
                            ? whatsappNumber
                            : 'Not set — tap to configure',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: hasNumber
                              ? cs.onSurface
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
