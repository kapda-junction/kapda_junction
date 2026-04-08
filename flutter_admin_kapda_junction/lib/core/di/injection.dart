import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/remote/auth_datasource.dart';
import '../../data/datasources/remote/coupon_datasource.dart';
import '../../data/datasources/remote/return_datasource.dart';
import '../../data/datasources/remote/banner_datasource.dart';
import '../../data/datasources/remote/category_datasource.dart';
import '../../data/datasources/remote/notification_datasource.dart';
import '../../data/datasources/remote/options_datasource.dart';
import '../../data/datasources/remote/order_datasource.dart';
import '../../data/datasources/remote/reviews_admin_datasource.dart';
import '../../data/datasources/remote/product_datasource.dart';
import '../../data/datasources/remote/settings_datasource.dart';
import '../../data/datasources/remote/upload_datasource.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/banners/banners_bloc.dart';
import '../../presentation/bloc/categories/categories_bloc.dart';
import '../../presentation/bloc/coupons/coupons_bloc.dart';
import '../../presentation/bloc/returns/returns_bloc.dart';
import '../../presentation/bloc/dashboard/dashboard_bloc.dart';
import '../../presentation/bloc/options/options_bloc.dart';
import '../../presentation/bloc/orders/orders_bloc.dart';
import '../../presentation/bloc/products/products_bloc.dart';
import '../../presentation/bloc/settings/settings_bloc.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerSingleton<LocalStorage>(LocalStorage(sl()));
  sl.registerSingleton<ApiClient>(ApiClient(sl()));

  // Data sources
  sl.registerSingleton<AuthDataSource>(AuthDataSource(sl(), sl()));
  sl.registerSingleton<ProductDataSource>(ProductDataSource(sl()));
  sl.registerSingleton<CategoryDataSource>(CategoryDataSource(sl()));
  sl.registerSingleton<NotificationDataSource>(NotificationDataSource(sl()));
  sl.registerSingleton<OrderDataSource>(OrderDataSource(sl()));
  sl.registerSingleton<BannerDataSource>(BannerDataSource(sl()));
  sl.registerSingleton<OptionsDataSource>(OptionsDataSource(sl()));
  sl.registerSingleton<UploadDataSource>(UploadDataSource(sl()));
  sl.registerSingleton<SettingsDataSource>(SettingsDataSource(sl()));
  sl.registerSingleton<CouponDataSource>(CouponDataSource(sl()));
  sl.registerSingleton<ReturnDataSource>(ReturnDataSource(sl()));
  sl.registerSingleton<ReviewsAdminDataSource>(ReviewsAdminDataSource(sl()));

  // BLoCs
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl(), sl()));
  sl.registerFactory<DashboardBloc>(() => DashboardBloc(sl(), sl(), sl()));
  sl.registerFactory<ProductsBloc>(() => ProductsBloc(sl(), sl()));
  sl.registerFactory<CategoriesBloc>(() => CategoriesBloc(sl()));
  sl.registerFactory<OrdersBloc>(() => OrdersBloc(sl()));
  sl.registerFactory<BannersBloc>(() => BannersBloc(sl()));
  sl.registerFactory<OptionsBloc>(() => OptionsBloc(sl()));
  sl.registerFactory<SettingsBloc>(() => SettingsBloc(sl()));
  sl.registerFactory<CouponsBloc>(() => CouponsBloc(sl()));
  sl.registerFactory<AdminReturnsBloc>(() => AdminReturnsBloc(sl()));
}
