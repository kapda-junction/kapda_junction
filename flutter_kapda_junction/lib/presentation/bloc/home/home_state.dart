part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<AppBanner> banners;
  final List<Category> categories;
  final List<Product> featuredProducts;
  final List<Product> allProducts;
  const HomeLoaded({
    required this.banners,
    required this.categories,
    required this.featuredProducts,
    required this.allProducts,
  });
  @override
  List<Object?> get props => [
    banners,
    categories,
    featuredProducts,
    allProducts,
  ];
}

class HomeFailure extends HomeState {
  final String message;
  const HomeFailure(this.message);
  @override
  List<Object?> get props => [message];
}
