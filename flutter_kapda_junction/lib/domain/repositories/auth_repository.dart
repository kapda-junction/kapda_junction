import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, (User, String)>> login(String email, String password);
  Future<Either<Failure, (User, String)>> register(
    String name,
    String email,
    String password,
  );
  Future<Either<Failure, User>> getMe();
  Future<void> logout();
  Future<String?> getSavedToken();
  Future<User?> getSavedUser();
}
