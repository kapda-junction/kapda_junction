import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/remote/return_datasource.dart';
import '../../../domain/entities/return_request.dart';

part 'returns_event.dart';
part 'returns_state.dart';

class AdminReturnsBloc extends Bloc<AdminReturnsEvent, AdminReturnsState> {
  final ReturnDataSource _ds;

  AdminReturnsBloc(this._ds) : super(AdminReturnsInitial()) {
    on<AdminReturnsLoadRequested>(_onLoad);
    on<AdminReturnUpdateRequested>(_onUpdate);
  }

  Future<void> _onLoad(AdminReturnsLoadRequested e, Emitter<AdminReturnsState> emit) async {
    emit(AdminReturnsLoading());
    try {
      final list = await _ds.getAll();
      emit(AdminReturnsLoaded(list));
    } catch (err) {
      emit(AdminReturnsFailure(err.toString()));
    }
  }

  Future<void> _onUpdate(AdminReturnUpdateRequested e, Emitter<AdminReturnsState> emit) async {
    emit(AdminReturnsSaving());
    try {
      await _ds.update(e.id, e.data);
      emit(AdminReturnSaveSuccess());
    } catch (err) {
      emit(AdminReturnsFailure(err.toString()));
    }
  }
}
