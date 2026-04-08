import 'package:equatable/equatable.dart';

class BannerProduct extends Equatable {
  final String id;
  final String name;
  final String? image;
  final double price;

  const BannerProduct({
    required this.id,
    required this.name,
    this.image,
    required this.price,
  });

  @override
  List<Object?> get props => [id];
}

class AppBanner extends Equatable {
  final String id;
  final String image;
  final List<BannerProduct> products;
  final int sortOrder;

  const AppBanner({
    required this.id,
    required this.image,
    required this.products,
    required this.sortOrder,
  });

  @override
  List<Object?> get props => [id];
}
