import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/remote/coupon_datasource.dart';
import '../../../domain/entities/coupon.dart';

part 'coupons_event.dart';
part 'coupons_state.dart';

class CouponsBloc extends Bloc<CouponsEvent, CouponsState> {
  final CouponDataSource _ds;

  CouponsBloc(this._ds) : super(CouponsInitial()) {
    on<CouponsLoadRequested>(_onLoad);
    on<CouponDeleteRequested>(_onDelete);
    on<CouponSaveRequested>(_onSave);
  }

  Future<void> _onLoad(CouponsLoadRequested e, Emitter<CouponsState> emit) async {
    emit(CouponsLoading());
    try {
      final coupons = await _ds.getAll();
      emit(CouponsLoaded(coupons: coupons));
    } catch (err) {
      emit(CouponsFailure(err.toString()));
    }
  }

  Future<void> _onDelete(CouponDeleteRequested e, Emitter<CouponsState> emit) async {
    try {
      await _ds.delete(e.id);
      if (state is CouponsLoaded) {
        final s = state as CouponsLoaded;
        emit(s.copyWith(coupons: s.coupons.where((c) => c.id != e.id).toList()));
      }
    } catch (err) {
      emit(CouponsFailure(err.toString()));
    }
  }

  Future<void> _onSave(CouponSaveRequested e, Emitter<CouponsState> emit) async {
    emit(CouponsSaving());
    try {
      if (e.id != null) {
        await _ds.update(e.id!, e.data);
      } else {
        await _ds.create(e.data);
      }
      emit(CouponSaveSuccess());
    } catch (err) {
      emit(CouponsFailure(err.toString()));
    }
  }
}
