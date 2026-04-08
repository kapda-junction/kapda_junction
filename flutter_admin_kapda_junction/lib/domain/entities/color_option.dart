import 'package:equatable/equatable.dart';

class ColorOption extends Equatable {
  final String id;
  final String name;
  const ColorOption({required this.id, required this.name});
  @override List<Object?> get props => [id];
}

class SizeOption extends Equatable {
  final String id;
  final String name;
  const SizeOption({required this.id, required this.name});
  @override List<Object?> get props => [id];
}
