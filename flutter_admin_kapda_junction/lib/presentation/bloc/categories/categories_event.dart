part of 'categories_bloc.dart';

abstract class CategoriesEvent extends Equatable {
  const CategoriesEvent();
  @override List<Object?> get props => [];
}

class CategoriesLoadRequested extends CategoriesEvent {}

class CategoryDeleteRequested extends CategoriesEvent {
  final String id;
  const CategoryDeleteRequested(this.id);
  @override List<Object?> get props => [id];
}

class CategorySaveRequested extends CategoriesEvent {
  final String? id;
  final Map<String, dynamic> data;
  const CategorySaveRequested({this.id, required this.data});
  @override List<Object?> get props => [id, data];
}

class CategoryToggleActiveRequested extends CategoriesEvent {
  final String id;
  final bool isActive;
  const CategoryToggleActiveRequested(this.id, this.isActive);
  @override List<Object?> get props => [id, isActive];
}
