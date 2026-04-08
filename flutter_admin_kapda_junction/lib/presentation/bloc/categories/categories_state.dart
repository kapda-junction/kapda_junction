part of 'categories_bloc.dart';

abstract class CategoriesState extends Equatable {
  const CategoriesState();
  @override List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {}
class CategoriesLoading extends CategoriesState {}
class CategoriesSaving extends CategoriesState {}
class CategorySaveSuccess extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final List<Category> categories;
  const CategoriesLoaded({required this.categories});

  CategoriesLoaded copyWith({List<Category>? categories}) =>
      CategoriesLoaded(categories: categories ?? this.categories);

  @override List<Object?> get props => [categories];
}

class CategoriesFailure extends CategoriesState {
  final String message;
  const CategoriesFailure(this.message);
  @override List<Object?> get props => [message];
}
