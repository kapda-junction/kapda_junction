import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/remote/product_datasource.dart';
import '../../../data/datasources/remote/order_datasource.dart';
import '../../../data/datasources/remote/settings_datasource.dart';
import '../../../data/models/order_model.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ProductDataSource _products;
  final OrderDataSource _orders;
  final SettingsDataSource _settings;

  DashboardBloc(this._products, this._orders, this._settings)
      : super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(DashboardLoadRequested e, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final results = await Future.wait([
        _products.getProducts(limit: 1),
        _orders.getOrders(),
        _settings.getAllSettings(),
      ]);
      final productResult = results[0] as ({List products, int total, int pages});
      final orders = results[1] as List<AdminOrderModel>;
      final settingsMap = results[2] as Map<String, dynamic>;
      final whatsapp = settingsMap['whatsappInquiryNumber']?.toString() ?? '';

      int cnt(String status) =>
          orders.where((o) => o.status == status).length;

      final revenue = orders.fold<double>(0, (s, o) => s + o.totalAmount);

      final sorted = List<AdminOrderModel>.from(orders)
        ..sort((a, b) {
          final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
      final recentOrders = sorted
          .take(5)
          .map(
            (o) => DashboardRecentOrder(
              id: o.id,
              customerName: o.userName,
              totalAmount: o.totalAmount,
              status: o.status,
              createdAt: o.createdAt,
            ),
          )
          .toList();

      emit(DashboardLoaded(
        totalProducts: productResult.total,
        totalOrders: orders.length,
        pendingOrders: cnt('pending'),
        confirmedOrders: cnt('confirmed'),
        shippedOrders: cnt('shipped'),
        deliveredOrders: cnt('delivered'),
        cancelledOrders: cnt('cancelled'),
        totalRevenue: revenue,
        whatsappNumber: whatsapp,
        recentOrders: recentOrders,
      ));
    } catch (e) {
      emit(DashboardFailure(e.toString()));
    }
  }
}
