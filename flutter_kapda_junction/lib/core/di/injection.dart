import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/remote/activity_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/home_remote_datasource.dart';
import '../../data/datasources/remote/order_remote_datasource.dart';
import '../../data/datasources/remote/return_remote_datasource.dart';
import '../../data/datasources/remote/review_remote_datasource.dart';
import '../../data/datasources/remote/product_remote_datasource.dart';
import '../../data/datasources/remote/wishlist_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/cart/cart_bloc.dart';
import '../../presentation/bloc/home/home_bloc.dart';
import '../../presentation/bloc/orders/orders_bloc.dart';
import '../../presentation/bloc/returns/returns_bloc.dart';
import '../../presentation/bloc/products/products_bloc.dart';
import '../../presentation/bloc/wishlist/wishlist_bloc.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // Core
  sl.registerSingleton<LocalStorage>(LocalStorage(sl()));
  sl.registerSingleton<ApiClient>(ApiClient(sl()));

  // Data Sources
  sl.registerSingleton<AuthRemoteDataSource>(AuthRemoteDataSource(sl()));
  sl.registerSingleton<ProductRemoteDataSource>(ProductRemoteDataSource(sl()));
  sl.registerSingleton<OrderRemoteDataSource>(OrderRemoteDataSource(sl()));
  sl.registerSingleton<ReturnRemoteDataSource>(ReturnRemoteDataSource(sl()));
  sl.registerSingleton<ReviewRemoteDataSource>(ReviewRemoteDataSource(sl()));
  sl.registerSingleton<HomeRemoteDataSource>(HomeRemoteDataSource(sl()));
  sl.registerSingleton<WishlistDataSource>(WishlistDataSource(sl()));
  sl.registerSingleton<ActivityDataSource>(ActivityDataSource(sl()));

  // Repositories
  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl(sl(), sl()));
  sl.registerSingleton<ProductRepository>(ProductRepositoryImpl(sl()));
  sl.registerSingleton<OrderRepository>(OrderRepositoryImpl(sl()));

  // BLoCs
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));
  sl.registerFactory<CartBloc>(() => CartBloc(sl()));
  sl.registerFactory<HomeBloc>(() => HomeBloc(sl(), sl()));
  sl.registerFactory<ProductsBloc>(() => ProductsBloc(sl()));
  sl.registerFactory<OrdersBloc>(() => OrdersBloc(sl()));
  sl.registerFactory<ReturnsBloc>(() => ReturnsBloc(sl(), sl()));
  sl.registerFactory<WishlistBloc>(() => WishlistBloc(sl()));
}
