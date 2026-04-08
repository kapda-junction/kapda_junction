part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override List<Object?> get props => [];
}

class SettingsLoadRequested extends SettingsEvent {}

class WhatsappNumberUpdateRequested extends SettingsEvent {
  final String number;
  const WhatsappNumberUpdateRequested(this.number);
  @override List<Object?> get props => [number];
}

class StorePolicySaveRequested extends SettingsEvent {
  final bool returnsEnabled;
  final bool returnVideoRequired;
  final bool customerOrderCancelEnabled;
  final String sizeGuideHtml;
  const StorePolicySaveRequested({
    required this.returnsEnabled,
    required this.returnVideoRequired,
    required this.customerOrderCancelEnabled,
    required this.sizeGuideHtml,
  });
  @override
  List<Object?> get props =>
      [returnsEnabled, returnVideoRequired, customerOrderCancelEnabled, sizeGuideHtml];
}
