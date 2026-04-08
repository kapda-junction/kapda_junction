import '../../domain/entities/color_option.dart';

class ColorOptionModel extends ColorOption {
  const ColorOptionModel({required super.id, required super.name});
  factory ColorOptionModel.fromJson(Map<String, dynamic> j) =>
      ColorOptionModel(id: j['_id'] as String, name: j['name'] as String? ?? '');
  Map<String, dynamic> toJson() => {'name': name};
}

class SizeOptionModel extends SizeOption {
  const SizeOptionModel({required super.id, required super.name});
  factory SizeOptionModel.fromJson(Map<String, dynamic> j) =>
      SizeOptionModel(id: j['_id'] as String, name: j['name'] as String? ?? '');
  Map<String, dynamic> toJson() => {'name': name};
}
