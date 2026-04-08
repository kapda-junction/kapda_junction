import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/error/failures.dart';
import '../../core/storage/local_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final LocalStorage _storage;

  AuthRepositoryImpl(this._remote, this._storage);

  @override
  Future<Either<Failure, (User, String)>> login(
    String email,
    String password,
  ) async {
    try {
      final data = await _remote.login(email, password);
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _storage.saveToken(token);
      await _storage.saveUser(user.toJson());
      return Right((user, token));
    } on DioException catch (e) {
      final msg = _extractError(e);
      return Left(AuthFailure(msg));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, (User, String)>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final data = await _remote.register(name, email, password);
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _storage.saveToken(token);
      await _storage.saveUser(user.toJson());
      return Right((user, token));
    } on DioException catch (e) {
      return Left(AuthFailure(_extractError(e)));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getMe() async {
    try {
      final user = await _remote.getMe();
      return Right(user);
    } on DioException catch (e) {
      return Left(AuthFailure(_extractError(e)));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    await _storage.clearToken();
    await _storage.clearUser();
    await _storage.clearCart();
  }

  @override
  Future<String?> getSavedToken() => _storage.getToken();

  @override
  Future<User?> getSavedUser() => _storage.getSavedUserModel();

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) return data['message']?.toString() ?? e.message ?? 'Error';
    return e.message ?? 'Network error';
  }
}
