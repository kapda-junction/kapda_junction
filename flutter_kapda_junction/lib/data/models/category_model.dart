import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.slug,
    super.description,
    super.image,
    super.parentId,
    super.children,
    required super.sortOrder,
    required super.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List? ?? [];
    final children = rawChildren
        .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
        .toList();

    return CategoryModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      parentId: json['parent'] as String?,
      children: children,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
