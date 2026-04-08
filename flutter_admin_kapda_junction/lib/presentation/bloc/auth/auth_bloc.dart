import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/remote/auth_datasource.dart';
import '../../../core/storage/local_storage.dart';
import '../../../domain/entities/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthDataSource _ds;
  final LocalStorage _storage;

  AuthBloc(this._ds, this._storage) : super(const AuthState()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthCheckRequested>(_onCheck);
  }

  Future<void> _onLogin(AuthLoginRequested e, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final result = await _ds.login(e.email, e.password);
      emit(state.copyWith(status: AuthStatus.authenticated, user: result.user));
    } catch (err) {
      emit(state.copyWith(status: AuthStatus.error, error: err.toString()));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    await _ds.logout();
    emit(const AuthState());
  }

  Future<void> _onCheck(AuthCheckRequested e, Emitter<AuthState> emit) async {
    final token = _storage.getToken();
    if (token == null) { emit(const AuthState()); return; }
    try {
      final user = await _ds.getMe();
      if (!user.isAdmin) { await _ds.logout(); emit(const AuthState()); return; }
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      emit(const AuthState());
    }
  }
}
