part of 'banners_bloc.dart';

abstract class BannersState extends Equatable {
  const BannersState();
  @override List<Object?> get props => [];
}

class BannersInitial extends BannersState {}
class BannersLoading extends BannersState {}
class BannersSaving extends BannersState {}
class BannerSaveSuccess extends BannersState {}

class BannersLoaded extends BannersState {
  final List<AppBanner> banners;
  const BannersLoaded({required this.banners});

  BannersLoaded copyWith({List<AppBanner>? banners}) =>
      BannersLoaded(banners: banners ?? this.banners);

  @override List<Object?> get props => [banners];
}

class BannersFailure extends BannersState {
  final String message;
  const BannersFailure(this.message);
  @override List<Object?> get props => [message];
}
