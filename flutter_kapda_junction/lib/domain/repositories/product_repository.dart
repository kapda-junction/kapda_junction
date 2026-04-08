import 'package:dartz/dartz.dart';
import '../entities/product.dart';
import '../../core/error/failures.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts({
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? size,
    String? color,
    int page = 1,
  });
  Future<Either<Failure, List<Product>>> getFeaturedProducts();
  Future<Either<Failure, Product>> getProductById(String id);
  Future<Either<Failure, List<Product>>> aiSearch(String query);
}
