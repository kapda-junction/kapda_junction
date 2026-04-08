import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/remote/category_datasource.dart';
import '../../../domain/entities/category.dart';

part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoryDataSource _ds;

  CategoriesBloc(this._ds) : super(CategoriesInitial()) {
    on<CategoriesLoadRequested>(_onLoad);
    on<CategoryDeleteRequested>(_onDelete);
    on<CategorySaveRequested>(_onSave);
    on<CategoryToggleActiveRequested>(_onToggle);
  }

  Future<void> _onLoad(CategoriesLoadRequested e, Emitter<CategoriesState> emit) async {
    emit(CategoriesLoading());
    try {
      final cats = await _ds.getAll();
      emit(CategoriesLoaded(categories: cats));
    } catch (err) {
      emit(CategoriesFailure(err.toString()));
    }
  }

  Future<void> _onDelete(CategoryDeleteRequested e, Emitter<CategoriesState> emit) async {
    try {
      await _ds.delete(e.id);
      if (state is CategoriesLoaded) {
        final s = state as CategoriesLoaded;
        emit(s.copyWith(categories: s.categories.where((c) => c.id != e.id).toList()));
      }
    } catch (err) {
      emit(CategoriesFailure(err.toString()));
    }
  }

  Future<void> _onSave(CategorySaveRequested e, Emitter<CategoriesState> emit) async {
    emit(CategoriesSaving());
    try {
      if (e.id != null) {
        await _ds.update(e.id!, e.data);
      } else {
        await _ds.create(e.data);
      }
      emit(CategorySaveSuccess());
    } catch (err) {
      emit(CategoriesFailure(err.toString()));
    }
  }

  Future<void> _onToggle(CategoryToggleActiveRequested e, Emitter<CategoriesState> emit) async {
    try {
      await _ds.update(e.id, {'isActive': e.isActive});
      if (state is CategoriesLoaded) {
        final s = state as CategoriesLoaded;
        final updated = s.categories.map((c) {
          if (c.id == e.id) return c.copyWith(isActive: e.isActive);
          return c;
        }).toList();
        emit(s.copyWith(categories: updated));
      }
    } catch (err) {
      emit(CategoriesFailure(err.toString()));
    }
  }
}
