import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/remote/settings_datasource.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsDataSource _ds;

  SettingsBloc(this._ds) : super(SettingsInitial()) {
    on<SettingsLoadRequested>(_onLoad);
    on<WhatsappNumberUpdateRequested>(_onUpdateWhatsapp);
    on<StorePolicySaveRequested>(_onSavePolicy);
  }

  SettingsLoaded _mapToLoaded(Map<String, dynamic> m) {
    return SettingsLoaded(
      whatsappNumber: m['whatsappInquiryNumber']?.toString() ?? '',
      returnsEnabled: m['returnsEnabled'] != false,
      returnVideoRequired: m['returnVideoRequired'] != false,
      customerOrderCancelEnabled: m['customerOrderCancelEnabled'] != false,
      sizeGuideHtml: m['sizeGuideHtml']?.toString() ?? '',
    );
  }

  Future<void> _onLoad(SettingsLoadRequested e, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    try {
      final m = await _ds.getAllSettings();
      emit(_mapToLoaded(m));
    } catch (err) {
      emit(SettingsFailure(err.toString()));
    }
  }

  Future<void> _onUpdateWhatsapp(WhatsappNumberUpdateRequested e, Emitter<SettingsState> emit) async {
    emit(SettingsSaving());
    try {
      final m = await _ds.updateSettings({
        'whatsappInquiryNumber': e.number,
      });
      emit(_mapToLoaded(m));
    } catch (err) {
      emit(SettingsFailure(err.toString()));
    }
  }

  Future<void> _onSavePolicy(StorePolicySaveRequested e, Emitter<SettingsState> emit) async {
    emit(SettingsSaving());
    try {
      final m = await _ds.updateSettings({
        'returnsEnabled': e.returnsEnabled,
        'returnVideoRequired': e.returnVideoRequired,
        'customerOrderCancelEnabled': e.customerOrderCancelEnabled,
        'sizeGuideHtml': e.sizeGuideHtml,
      });
      emit(_mapToLoaded(m));
    } catch (err) {
      emit(SettingsFailure(err.toString()));
    }
  }
}
