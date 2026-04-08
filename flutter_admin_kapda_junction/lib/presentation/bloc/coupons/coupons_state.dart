part of 'coupons_bloc.dart';

abstract class CouponsState extends Equatable {
  const CouponsState();
  @override
  List<Object?> get props => [];
}

class CouponsInitial extends CouponsState {}

class CouponsLoading extends CouponsState {}

class CouponsSaving extends CouponsState {}

class CouponSaveSuccess extends CouponsState {}

class CouponsLoaded extends CouponsState {
  final List<Coupon> coupons;
  const CouponsLoaded({required this.coupons});

  CouponsLoaded copyWith({List<Coupon>? coupons}) =>
      CouponsLoaded(coupons: coupons ?? this.coupons);

  @override
  List<Object?> get props => [coupons];
}

class CouponsFailure extends CouponsState {
  final String message;
  const CouponsFailure(this.message);
  @override
  List<Object?> get props => [message];
}
