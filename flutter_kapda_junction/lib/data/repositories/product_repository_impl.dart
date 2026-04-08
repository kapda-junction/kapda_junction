import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/remote/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remote;
  ProductRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<Product>>> getProducts({
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? size,
    String? color,
    int page = 1,
  }) async {
    try {
      final products = await _remote.getProducts(
        search: search,
        category: category,
        minPrice: minPrice,
        maxPrice: maxPrice,
        size: size,
        color: color,
        page: page,
      );
      return Right(products);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e), statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getFeaturedProducts() async {
    try {
      final products = await _remote.getFeaturedProducts();
      return Right(products);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      final product = await _remote.getProductById(id);
      return Right(product);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> aiSearch(String query) async {
    try {
      final products = await _remote.aiSearch(query);
      return Right(products);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) return data['message']?.toString() ?? 'Error';
    return e.message ?? 'Network error';
  }
}
