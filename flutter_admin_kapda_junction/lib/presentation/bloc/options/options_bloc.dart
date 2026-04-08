import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/remote/options_datasource.dart';
import '../../../domain/entities/color_option.dart';

part 'options_event.dart';
part 'options_state.dart';

class OptionsBloc extends Bloc<OptionsEvent, OptionsState> {
  final OptionsDataSource _ds;

  OptionsBloc(this._ds) : super(OptionsInitial()) {
    on<OptionsLoadRequested>(_onLoad);
    on<ColorCreateRequested>(_onCreateColor);
    on<ColorUpdateRequested>(_onUpdateColor);
    on<ColorDeleteRequested>(_onDeleteColor);
    on<SizeCreateRequested>(_onCreateSize);
    on<SizeUpdateRequested>(_onUpdateSize);
    on<SizeDeleteRequested>(_onDeleteSize);
  }

  Future<void> _onLoad(OptionsLoadRequested e, Emitter<OptionsState> emit) async {
    emit(OptionsLoading());
    try {
      final colors = await _ds.getColors();
      final sizes = await _ds.getSizes();
      emit(OptionsLoaded(colors: colors, sizes: sizes));
    } catch (err) {
      emit(OptionsFailure(err.toString()));
    }
  }

  Future<void> _onCreateColor(ColorCreateRequested e, Emitter<OptionsState> emit) async {
    try {
      final color = await _ds.createColor(e.name);
      if (state is OptionsLoaded) {
        final s = state as OptionsLoaded;
        emit(s.copyWith(colors: [...s.colors, color]));
      }
    } catch (err) {
      emit(OptionsFailure(err.toString()));
    }
  }

  Future<void> _onUpdateColor(ColorUpdateRequested e, Emitter<OptionsState> emit) async {
    try {
      final updated = await _ds.updateColor(e.id, e.name);
      if (state is OptionsLoaded) {
        final s = state as OptionsLoaded;
        emit(s.copyWith(colors: s.colors.map((c) => c.id == e.id ? updated : c).toList()));
      }
    } catch (err) {
      emit(OptionsFailure(err.toString()));
    }
  }

  Future<void> _onDeleteColor(ColorDeleteRequested e, Emitter<OptionsState> emit) async {
    try {
      await _ds.deleteColor(e.id);
      if (state is OptionsLoaded) {
        final s = state as OptionsLoaded;
        emit(s.copyWith(colors: s.colors.where((c) => c.id != e.id).toList()));
      }
    } catch (err) {
      emit(OptionsFailure(err.toString()));
    }
  }

  Future<void> _onCreateSize(SizeCreateRequested e, Emitter<OptionsState> emit) async {
    try {
      final size = await _ds.createSize(e.name);
      if (state is OptionsLoaded) {
        final s = state as OptionsLoaded;
        emit(s.copyWith(sizes: [...s.sizes, size]));
      }
    } catch (err) {
      emit(OptionsFailure(err.toString()));
    }
  }

  Future<void> _onUpdateSize(SizeUpdateRequested e, Emitter<OptionsState> emit) async {
    try {
      final updated = await _ds.updateSize(e.id, e.name);
      if (state is OptionsLoaded) {
        final s = state as OptionsLoaded;
        emit(s.copyWith(sizes: s.sizes.map((sz) => sz.id == e.id ? updated : sz).toList()));
      }
    } catch (err) {
      emit(OptionsFailure(err.toString()));
    }
  }

  Future<void> _onDeleteSize(SizeDeleteRequested e, Emitter<OptionsState> emit) async {
    try {
      await _ds.deleteSize(e.id);
      if (state is OptionsLoaded) {
        final s = state as OptionsLoaded;
        emit(s.copyWith(sizes: s.sizes.where((sz) => sz.id != e.id).toList()));
      }
    } catch (err) {
      emit(OptionsFailure(err.toString()));
    }
  }
}
