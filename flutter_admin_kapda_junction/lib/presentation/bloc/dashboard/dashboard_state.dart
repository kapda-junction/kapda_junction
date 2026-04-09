part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}

class DashboardRecentOrder extends Equatable {
  final String id;
  final String customerName;
  final double totalAmount;
  final String status;
  final DateTime? createdAt;

  const DashboardRecentOrder({
    required this.id,
    required this.customerName,
    required this.totalAmount,
    required this.status,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, customerName, totalAmount, status, createdAt];
}

class DashboardLoaded extends DashboardState {
  final int totalProducts;
  final int totalOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final String whatsappNumber;
  final List<DashboardRecentOrder> recentOrders;

  const DashboardLoaded({
    required this.totalProducts,
    required this.totalOrders,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.shippedOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    required this.whatsappNumber,
    required this.recentOrders,
  });

  @override
  List<Object?> get props => [
        totalProducts,
        totalOrders,
        pendingOrders,
        confirmedOrders,
        shippedOrders,
        deliveredOrders,
        cancelledOrders,
        totalRevenue,
        whatsappNumber,
        recentOrders,
      ];
}

class DashboardFailure extends DashboardState {
  final String message;
  const DashboardFailure(this.message);
  @override List<Object?> get props => [message];
}
