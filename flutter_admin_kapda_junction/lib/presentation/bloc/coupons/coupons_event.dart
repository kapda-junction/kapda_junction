part of 'coupons_bloc.dart';

abstract class CouponsEvent extends Equatable {
  const CouponsEvent();
  @override
  List<Object?> get props => [];
}

class CouponsLoadRequested extends CouponsEvent {}

class CouponDeleteRequested extends CouponsEvent {
  final String id;
  const CouponDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class CouponSaveRequested extends CouponsEvent {
  final String? id;
  final Map<String, dynamic> data;
  const CouponSaveRequested({this.id, required this.data});
  @override
  List<Object?> get props => [id, data];
}
