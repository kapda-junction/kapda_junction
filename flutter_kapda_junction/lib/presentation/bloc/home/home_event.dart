part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeLoadRequested extends HomeEvent {
  final bool forceRefresh;

  const HomeLoadRequested({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}
