import 'package:equatable/equatable.dart';

class BannerProduct extends Equatable {
  final String id;
  final String name;
  final double price;
  final String? image;

  const BannerProduct({required this.id, required this.name, required this.price, this.image});

  @override
  List<Object?> get props => [id];
}

class AppBanner extends Equatable {
  final String id;
  final String image;
  final List<BannerProduct> products;
  final int sortOrder;
  final bool isActive;

  const AppBanner({
    required this.id, required this.image, required this.products,
    required this.sortOrder, required this.isActive,
  });

  @override
  List<Object?> get props => [id];
}
