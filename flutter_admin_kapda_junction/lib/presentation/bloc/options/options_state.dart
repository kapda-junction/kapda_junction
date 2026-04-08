part of 'options_bloc.dart';

abstract class OptionsState extends Equatable {
  const OptionsState();
  @override List<Object?> get props => [];
}

class OptionsInitial extends OptionsState {}
class OptionsLoading extends OptionsState {}

class OptionsLoaded extends OptionsState {
  final List<ColorOption> colors;
  final List<SizeOption> sizes;

  const OptionsLoaded({required this.colors, required this.sizes});

  OptionsLoaded copyWith({List<ColorOption>? colors, List<SizeOption>? sizes}) =>
      OptionsLoaded(
        colors: colors ?? this.colors,
        sizes: sizes ?? this.sizes,
      );

  @override List<Object?> get props => [colors, sizes];
}

class OptionsFailure extends OptionsState {
  final String message;
  const OptionsFailure(this.message);
  @override List<Object?> get props => [message];
}
