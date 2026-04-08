import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/remote/wishlist_datasource.dart';

part 'wishlist_event.dart';
part 'wishlist_state.dart';

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final WishlistDataSource _ds;

  WishlistBloc(this._ds) : super(const WishlistState()) {
    on<WishlistLoadRequested>(_onLoad);
    on<WishlistToggleRequested>(_onToggle);
    on<WishlistCleared>(_onClear);
    on<WishlistIdsUpdated>((e, emit) => emit(state.copyWith(ids: e.ids)));
  }

  Future<void> _onLoad(WishlistLoadRequested e, Emitter<WishlistState> emit) async {
    emit(state.copyWith(loading: true));
    try {
      final ids = await _ds.getIds();
      emit(state.copyWith(ids: ids.toSet(), loading: false));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }

  Future<void> _onToggle(WishlistToggleRequested e, Emitter<WishlistState> emit) async {
    final current = Set<String>.from(state.ids);
    final isAdding = !current.contains(e.productId);

    // Optimistic update
    if (isAdding) {
      current.add(e.productId);
    } else {
      current.remove(e.productId);
    }
    emit(state.copyWith(ids: current));

    try {
      if (isAdding) {
        await _ds.add(e.productId);
      } else {
        await _ds.remove(e.productId);
      }
    } catch (_) {
      // Revert on failure
      final reverted = Set<String>.from(state.ids);
      if (isAdding) {
        reverted.remove(e.productId);
      } else {
        reverted.add(e.productId);
      }
      emit(state.copyWith(ids: reverted));
    }
  }

  void _onClear(WishlistCleared e, Emitter<WishlistState> emit) =>
      emit(const WishlistState());
}
