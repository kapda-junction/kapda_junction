import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? image;
  final String? parentId;
  final List<Category> children;
  final int sortOrder;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.image,
    this.parentId,
    this.children = const [],
    required this.sortOrder,
    required this.isActive,
  });

  bool get hasChildren => children.isNotEmpty;

  @override
  List<Object?> get props => [id, name, slug];
}
