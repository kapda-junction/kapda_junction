import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? image;
  final String? parentId;
  final String? parentName;
  final List<Category> children;
  final int sortOrder;
  final bool isActive;

  const Category({
    required this.id, required this.name, required this.slug,
    this.description, this.image, this.parentId, this.parentName,
    this.children = const [], required this.sortOrder, required this.isActive,
  });

  bool get hasChildren => children.isNotEmpty;

  Category copyWith({bool? isActive}) => Category(
    id: id, name: name, slug: slug, description: description, image: image,
    parentId: parentId, parentName: parentName, children: children,
    sortOrder: sortOrder, isActive: isActive ?? this.isActive,
  );

  @override
  List<Object?> get props => [id, name];
}
