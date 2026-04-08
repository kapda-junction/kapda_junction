import 'package:dartz/dartz.dart' hide Order;
import 'package:dio/dio.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/remote/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remote;
  OrderRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<Order>>> getOrders() async {
    try {
      final orders = await _remote.getOrders();
      return Right(orders);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Order>> getOrderById(String id) async {
    try {
      final order = await _remote.getOrderById(id);
      return Right(order);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> createPaymentOrder(
      Map<String, dynamic> body) async {
    try {
      final data = await _remote.createPaymentOrder(body);
      return Right(data);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Order>> verifyPayment(Map<String, dynamic> body) async {
    try {
      final order = await _remote.verifyPayment(body);
      return Right(order);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Order>> createOrder(Map<String, dynamic> body) async {
    try {
      final order = await _remote.createOrder(body);
      return Right(order);
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
