import 'package:dartz/dartz.dart' hide Order;
import '../entities/order.dart';
import '../../core/error/failures.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<Order>>> getOrders();
  Future<Either<Failure, Order>> getOrderById(String id);
  Future<Either<Failure, Map<String, dynamic>>> createPaymentOrder(Map<String, dynamic> body);
  Future<Either<Failure, Order>> verifyPayment(Map<String, dynamic> body);
  Future<Either<Failure, Order>> createOrder(Map<String, dynamic> body);
}
