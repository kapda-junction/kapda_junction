part of 'wishlist_bloc.dart';

abstract class WishlistEvent extends Equatable {
  const WishlistEvent();
  @override
  List<Object?> get props => [];
}

class WishlistLoadRequested extends WishlistEvent {
  const WishlistLoadRequested();
}

class WishlistToggleRequested extends WishlistEvent {
  final String productId;
  const WishlistToggleRequested(this.productId);
  @override
  List<Object?> get props => [productId];
}

class WishlistCleared extends WishlistEvent {
  const WishlistCleared();
}

class WishlistIdsUpdated extends WishlistEvent {
  final Set<String> ids;
  const WishlistIdsUpdated(this.ids);
  @override
  List<Object?> get props => [ids];
}
