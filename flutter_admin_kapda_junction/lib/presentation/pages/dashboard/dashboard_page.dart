import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../widgets/common/admin_drawer.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DashboardBloc>()..add(DashboardLoadRequested()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(title: const Text('Dashboard')),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardFailure) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text(state.message),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.read<DashboardBloc>().add(DashboardLoadRequested()),
                  child: const Text('Retry'),
                ),
              ]),
            );
          }
          if (state is DashboardLoaded) {
            final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
            return RefreshIndicator(
              onRefresh: () async => context.read<DashboardBloc>().add(DashboardLoadRequested()),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _StatCard(label: 'Total Products', value: '${state.totalProducts}',
                            icon: Icons.inventory_2_outlined, color: Colors.blue),
                        _StatCard(label: 'Total Orders', value: '${state.totalOrders}',
                            icon: Icons.receipt_long_outlined, color: Colors.orange),
                        _StatCard(label: 'Pending Orders', value: '${state.pendingOrders}',
                            icon: Icons.pending_outlined, color: Colors.amber),
                        _StatCard(label: 'Delivered', value: '${state.deliveredOrders}',
                            icon: Icons.check_circle_outline, color: Colors.green),
                        _StatCard(label: 'Total Revenue', value: fmt.format(state.totalRevenue),
                            icon: Icons.currency_rupee, color: Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF25D366),
                          child: Icon(Icons.chat, color: Colors.white, size: 20),
                        ),
                        title: const Text('WhatsApp Inquiry Number'),
                        subtitle: Text(state.whatsappNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(30),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
