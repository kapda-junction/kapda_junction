import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final token = await _repo.getSavedToken();
    if (token == null) {
      emit(AuthUnauthenticated());
      return;
    }
    final savedUser = await _repo.getSavedUser();
    if (savedUser != null) {
      emit(AuthAuthenticated(user: savedUser, token: token));
      return;
    }
    emit(AuthLoading());
    final result = await _repo.getMe();
    result.fold(
      (_) => emit(AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user: user, token: token)),
    );
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _repo.login(event.email, event.password);
    result.fold(
      (f) => emit(AuthFailureState(f.message)),
      (pair) => emit(AuthAuthenticated(user: pair.$1, token: pair.$2)),
    );
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _repo.register(
      event.name,
      event.email,
      event.password,
    );
    result.fold(
      (f) => emit(AuthFailureState(f.message)),
      (pair) => emit(AuthAuthenticated(user: pair.$1, token: pair.$2)),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.logout();
    emit(AuthUnauthenticated());
  }
}
