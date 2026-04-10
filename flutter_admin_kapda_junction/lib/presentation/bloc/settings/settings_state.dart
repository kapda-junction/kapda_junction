part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}
class SettingsLoading extends SettingsState {}
class SettingsSaving extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final String whatsappNumber;
  final String appDownloadUrl;
  final bool returnsEnabled;
  final bool returnVideoRequired;
  final bool customerOrderCancelEnabled;
  final String sizeGuideHtml;

  const SettingsLoaded({
    required this.whatsappNumber,
    required this.appDownloadUrl,
    required this.returnsEnabled,
    required this.returnVideoRequired,
    required this.customerOrderCancelEnabled,
    required this.sizeGuideHtml,
  });

  @override
  List<Object?> get props => [
        whatsappNumber,
        appDownloadUrl,
        returnsEnabled,
        returnVideoRequired,
        customerOrderCancelEnabled,
        sizeGuideHtml,
      ];
}

class SettingsFailure extends SettingsState {
  final String message;
  const SettingsFailure(this.message);
  @override List<Object?> get props => [message];
}
