part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final int totalProducts, totalOrders, pendingOrders, deliveredOrders;
  final double totalRevenue;
  final String whatsappNumber;

  const DashboardLoaded({
    required this.totalProducts, required this.totalOrders,
    required this.pendingOrders, required this.deliveredOrders,
    required this.totalRevenue, required this.whatsappNumber,
  });
  @override List<Object?> get props => [totalProducts, totalOrders, totalRevenue];
}

class DashboardFailure extends DashboardState {
  final String message;
  const DashboardFailure(this.message);
  @override List<Object?> get props => [message];
}
