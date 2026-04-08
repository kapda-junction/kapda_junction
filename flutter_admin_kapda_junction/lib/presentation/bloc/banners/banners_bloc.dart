import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/remote/banner_datasource.dart';
import '../../../domain/entities/banner.dart';

part 'banners_event.dart';
part 'banners_state.dart';

class BannersBloc extends Bloc<BannersEvent, BannersState> {
  final BannerDataSource _ds;

  BannersBloc(this._ds) : super(BannersInitial()) {
    on<BannersLoadRequested>(_onLoad);
    on<BannerDeleteRequested>(_onDelete);
    on<BannerSaveRequested>(_onSave);
  }

  Future<void> _onLoad(BannersLoadRequested e, Emitter<BannersState> emit) async {
    emit(BannersLoading());
    try {
      final banners = await _ds.getAll();
      emit(BannersLoaded(banners: banners));
    } catch (err) {
      emit(BannersFailure(err.toString()));
    }
  }

  Future<void> _onDelete(BannerDeleteRequested e, Emitter<BannersState> emit) async {
    try {
      await _ds.delete(e.id);
      if (state is BannersLoaded) {
        final s = state as BannersLoaded;
        emit(s.copyWith(banners: s.banners.where((b) => b.id != e.id).toList()));
      }
    } catch (err) {
      emit(BannersFailure(err.toString()));
    }
  }

  Future<void> _onSave(BannerSaveRequested e, Emitter<BannersState> emit) async {
    emit(BannersSaving());
    try {
      if (e.id != null) {
        await _ds.update(e.id!, e.data);
      } else {
        await _ds.create(e.data);
      }
      emit(BannerSaveSuccess());
    } catch (err) {
      emit(BannersFailure(err.toString()));
    }
  }
}
