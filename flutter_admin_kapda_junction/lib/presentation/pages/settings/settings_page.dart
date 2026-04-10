import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../data/datasources/remote/settings_datasource.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../../widgets/common/admin_drawer.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SettingsBloc>()..add(SettingsLoadRequested()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();
  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  final _ctrl = TextEditingController();
  final _appDownloadCtrl = TextEditingController();
  final _userIdCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _dataCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  bool _sendingNotification = false;

  bool _returnsEnabled = true;
  bool _returnVideoRequired = true;
  bool _customerOrderCancelEnabled = true;
  final _sizeGuideCtrl = TextEditingController();
  bool _sizeGuideLoaded = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _appDownloadCtrl.dispose();
    _userIdCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _dataCtrl.dispose();
    _imageCtrl.dispose();
    _sizeGuideCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _parseDataJson() {
    final raw = _dataCtrl.text.trim();
    if (raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('data must be a JSON object');
    }
    return decoded;
  }

  Future<void> _sendNotification() async {
    final userId = _userIdCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (userId.isEmpty || title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID, title and body are required')),
      );
      return;
    }

    setState(() => _sendingNotification = true);
    try {
      final data = _parseDataJson();
      final res = await sl<SettingsDataSource>().sendUserNotification(
        userId: userId,
        title: title,
        body: body,
        data: data,
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
      );
      if (!mounted) return;
      final sent = res['sentCount'] ?? 0;
      final failed = res['failureCount'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification sent: $sent success, $failed failed')),
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid data JSON: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e')),
      );
    } finally {
      if (mounted) setState(() => _sendingNotification = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(title: const Text('Settings')),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsLoaded) {
            if (_ctrl.text.isEmpty) {
              _ctrl.text = state.whatsappNumber;
            }
            if (_appDownloadCtrl.text.isEmpty) {
              _appDownloadCtrl.text = state.appDownloadUrl;
            }
            setState(() {
              _returnsEnabled = state.returnsEnabled;
              _returnVideoRequired = state.returnVideoRequired;
              _customerOrderCancelEnabled = state.customerOrderCancelEnabled;
            });
            if (!_sizeGuideLoaded) {
              _sizeGuideCtrl.text = state.sizeGuideHtml;
              _sizeGuideLoaded = true;
            }
          }
          if (state is SettingsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) return const Center(child: CircularProgressIndicator());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WhatsApp Inquiry', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Customers will contact you on this number for product inquiries.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '919770525851',
                        helperText: 'Include country code (e.g. 91 for India)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: state is SettingsSaving
                        ? null
                        : () {
                            if (_ctrl.text.trim().isNotEmpty) {
                              context.read<SettingsBloc>().add(WhatsappNumberUpdateRequested(_ctrl.text.trim()));
                            }
                          },
                    child: state is SettingsSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ]),
                const SizedBox(height: 28),
                Text(
                  'App download link (share page)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Google Drive, Play Store, or APK link. Shown on product share pages when the visitor does not have the app.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _appDownloadCtrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Download URL',
                        prefixIcon: Icon(Icons.link),
                        hintText: 'https://drive.google.com/...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: state is SettingsSaving
                        ? null
                        : () {
                            context.read<SettingsBloc>().add(
                                  AppDownloadUrlSaveRequested(_appDownloadCtrl.text.trim()),
                                );
                          },
                    child: state is SettingsSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ]),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Store policy',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Control returns, proof video, and whether customers can cancel orders before shipment.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow returns & exchanges'),
                  subtitle: const Text('When off, customers cannot submit return requests.'),
                  value: _returnsEnabled,
                  onChanged: state is SettingsSaving
                      ? null
                      : (v) => setState(() {
                            _returnsEnabled = v;
                            if (!v) _returnVideoRequired = false;
                          }),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Require product video'),
                  subtitle: const Text('Customers must upload a short clip with every return / exchange request.'),
                  value: _returnVideoRequired,
                  onChanged: (state is SettingsSaving || !_returnsEnabled)
                      ? null
                      : (v) => setState(() => _returnVideoRequired = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow customer order cancel'),
                  subtitle: const Text('Lets customers cancel from the app while the order is pending or confirmed (not shipped).'),
                  value: _customerOrderCancelEnabled,
                  onChanged: state is SettingsSaving ? null : (v) => setState(() => _customerOrderCancelEnabled = v),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: state is SettingsSaving
                        ? null
                        : () {
                            context.read<SettingsBloc>().add(
                                  StorePolicySaveRequested(
                                    returnsEnabled: _returnsEnabled,
                                    returnVideoRequired: _returnVideoRequired,
                                    customerOrderCancelEnabled: _customerOrderCancelEnabled,
                                    sizeGuideHtml: _sizeGuideCtrl.text,
                                  ),
                                );
                          },
                    child: state is SettingsSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Text('Save policy'),
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Size guide (customer app)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'HTML shown on Profile → Size guide. Use simple tables or lists.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _sizeGuideCtrl,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    alignLabelWithHint: true,
                    labelText: 'HTML',
                    hintText: '<p>Chest (inches) …</p>',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Saved together with “Save policy” above.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Send Custom Push Notification',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Send a custom notification to a specific user (requires user Mongo ID).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _userIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    hintText: 'Mongo user _id',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notification Title',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bodyCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notification Body',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.message_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _imageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _dataCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Data JSON (optional)',
                    hintText: '{"type":"order","orderId":"123"}',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.data_object),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _sendingNotification ? null : _sendNotification,
                    icon: _sendingNotification
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_sendingNotification ? 'Sending...' : 'Send Notification'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
