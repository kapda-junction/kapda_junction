import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/remote/product_datasource.dart';
import '../../../data/datasources/remote/order_datasource.dart';
import '../../../data/datasources/remote/settings_datasource.dart';

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
      final orders = results[1] as List;
      final settingsMap = results[2] as Map<String, dynamic>;
      final whatsapp = settingsMap['whatsappInquiryNumber']?.toString() ?? '';

      final pending   = orders.where((o) => o.status == 'pending').length;
      final revenue   = orders.fold<double>(0, (s, o) => s + o.totalAmount);
      final delivered = orders.where((o) => o.status == 'delivered').length;

      emit(DashboardLoaded(
        totalProducts: productResult.total,
        totalOrders: orders.length,
        pendingOrders: pending,
        deliveredOrders: delivered,
        totalRevenue: revenue,
        whatsappNumber: whatsapp,
      ));
    } catch (e) {
      emit(DashboardFailure(e.toString()));
    }
  }
}
