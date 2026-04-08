import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/remote/home_remote_datasource.dart';
import '../../../data/datasources/remote/return_remote_datasource.dart';
import '../../../domain/entities/return_request.dart';

part 'returns_event.dart';
part 'returns_state.dart';

class ReturnsBloc extends Bloc<ReturnsEvent, ReturnsState> {
  final ReturnRemoteDataSource _ds;
  final HomeRemoteDataSource _home;

  ReturnsBloc(this._ds, this._home) : super(ReturnsInitial()) {
    on<ReturnsLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(ReturnsLoadRequested e, Emitter<ReturnsState> emit) async {
    emit(ReturnsLoading());
    try {
      final list = await _ds.list(orderId: e.orderId);
      final settings = await _home.getSettings();
      final enabled = settings['returnsEnabled'] != false;
      emit(ReturnsLoaded(returns: list, returnsEnabled: enabled));
    } catch (err) {
      emit(ReturnsFailure(err.toString()));
    }
  }
}
