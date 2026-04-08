part of 'options_bloc.dart';

abstract class OptionsEvent extends Equatable {
  const OptionsEvent();
  @override List<Object?> get props => [];
}

class OptionsLoadRequested extends OptionsEvent {}

class ColorCreateRequested extends OptionsEvent {
  final String name;
  const ColorCreateRequested(this.name);
  @override List<Object?> get props => [name];
}

class ColorUpdateRequested extends OptionsEvent {
  final String id;
  final String name;
  const ColorUpdateRequested(this.id, this.name);
  @override List<Object?> get props => [id, name];
}

class ColorDeleteRequested extends OptionsEvent {
  final String id;
  const ColorDeleteRequested(this.id);
  @override List<Object?> get props => [id];
}

class SizeCreateRequested extends OptionsEvent {
  final String name;
  const SizeCreateRequested(this.name);
  @override List<Object?> get props => [name];
}

class SizeUpdateRequested extends OptionsEvent {
  final String id;
  final String name;
  const SizeUpdateRequested(this.id, this.name);
  @override List<Object?> get props => [id, name];
}

class SizeDeleteRequested extends OptionsEvent {
  final String id;
  const SizeDeleteRequested(this.id);
  @override List<Object?> get props => [id];
}
