part of 'banners_bloc.dart';

abstract class BannersEvent extends Equatable {
  const BannersEvent();
  @override List<Object?> get props => [];
}

class BannersLoadRequested extends BannersEvent {}

class BannerDeleteRequested extends BannersEvent {
  final String id;
  const BannerDeleteRequested(this.id);
  @override List<Object?> get props => [id];
}

class BannerSaveRequested extends BannersEvent {
  final String? id;
  final Map<String, dynamic> data;
  const BannerSaveRequested({this.id, required this.data});
  @override List<Object?> get props => [id, data];
}
