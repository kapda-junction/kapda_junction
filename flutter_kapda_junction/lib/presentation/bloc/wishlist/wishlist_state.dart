part of 'wishlist_bloc.dart';

class WishlistState extends Equatable {
  final Set<String> ids;
  final bool loading;

  const WishlistState({this.ids = const {}, this.loading = false});

  bool contains(String productId) => ids.contains(productId);

  WishlistState copyWith({Set<String>? ids, bool? loading}) =>
      WishlistState(ids: ids ?? this.ids, loading: loading ?? this.loading);

  @override
  List<Object?> get props => [ids, loading];
}
