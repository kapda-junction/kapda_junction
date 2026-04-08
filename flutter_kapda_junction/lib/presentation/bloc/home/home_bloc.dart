import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/banner.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../data/datasources/remote/home_remote_datasource.dart';
import '../../../data/datasources/remote/product_remote_datasource.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRemoteDataSource _homeDs;
  final ProductRemoteDataSource _productDs;
  static HomeLoaded? _cache;

  HomeBloc(this._homeDs, this._productDs) : super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(HomeLoadRequested event, Emitter<HomeState> emit) async {
    if (!event.forceRefresh && _cache != null) {
      emit(_cache!);
      return;
    }
    emit(HomeLoading());
    try {
      final results = await Future.wait([
        _homeDs.getActiveBanners(),
        _homeDs.getCategoryTree(),
        _productDs.getFeaturedProducts(),
        _productDs.getProducts(limit: 120),
      ]);
      final loaded = HomeLoaded(
        banners: results[0] as List<AppBanner>,
        categories: results[1] as List<Category>,
        featuredProducts: results[2] as List<Product>,
        allProducts: results[3] as List<Product>,
      );
      _cache = loaded;
      emit(loaded);
    } catch (e) {
      emit(HomeFailure(e.toString()));
    }
  }
}
