import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id, required super.name, required super.slug,
    super.description, super.image, super.parentId, super.parentName,
    super.children, required super.sortOrder, required super.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> j) {
    final parent = j['parent'];
    return CategoryModel(
      id: j['_id'] as String,
      name: j['name'] as String? ?? '',
      slug: j['slug'] as String? ?? '',
      description: j['description'] as String?,
      image: j['image'] as String?,
      parentId: parent is Map ? parent['_id'] as String? : parent as String?,
      parentName: parent is Map ? parent['name'] as String? : null,
      children: (j['children'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList(),
      sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: j['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    if (image != null) 'image': image,
    'parent': parentId,
    'sortOrder': sortOrder,
    'isActive': isActive,
  };
}
