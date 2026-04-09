import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/error/app_error_handler.dart';
import '../../../core/network/api_client.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  bool _loading = true;
  bool _saving = false;
  bool _addressSheetOpen = false;
  List<Map<String, dynamic>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loading = true);
    try {
      final res = await sl<ApiClient>().get(ApiConstants.addresses);
      final map = Map<String, dynamic>.from(res.data as Map);
      final list = (map['addresses'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) return;
      setState(() => _addresses = list);
    } catch (e) {
      if (!mounted) return;
      AppErrorHandler.show('Failed to load addresses. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAddress(String id) async {
    setState(() => _saving = true);
    try {
      await sl<ApiClient>().delete('${ApiConstants.addresses}/$id');
      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      AppErrorHandler.show('Failed to delete address. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setDefault(String id) async {
    setState(() => _saving = true);
    try {
      await sl<ApiClient>().patch('${ApiConstants.addresses}/$id/default');
      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      AppErrorHandler.show('Failed to update default address. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showAddressForm({Map<String, dynamic>? existing}) async {
    if (_addressSheetOpen) return;
    _addressSheetOpen = true;
    final nameCtrl = TextEditingController(text: (existing?['name'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (existing?['phone'] ?? '').toString());
    final addressCtrl = TextEditingController(text: (existing?['address'] ?? '').toString());
    final cityCtrl = TextEditingController(text: (existing?['city'] ?? '').toString());
    final stateCtrl = TextEditingController(text: (existing?['state'] ?? '').toString());
    final pincodeCtrl = TextEditingController(text: (existing?['pincode'] ?? '').toString());
    final labelCtrl = TextEditingController(text: (existing?['label'] ?? 'Home').toString());
    bool isDefault = existing?['isDefault'] == true;
    final formKey = GlobalKey<FormState>();
    bool formSaving = false;

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      existing == null ? 'Add Address' : 'Edit Address',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(labelText: 'Label (Home/Office)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: (v) => (v == null || v.trim().length < 10) ? 'Enter valid phone' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cityCtrl,
                            decoration: const InputDecoration(labelText: 'City'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: stateCtrl,
                            decoration: const InputDecoration(labelText: 'State'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: pincodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Pincode'),
                      validator: (v) => (v == null || v.trim().length < 6) ? 'Enter valid pincode' : null,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isDefault,
                      onChanged: formSaving ? null : (v) => setSheetState(() => isDefault = v),
                      title: const Text('Set as default address'),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: formSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => formSaving = true);
                                final payload = {
                                  'label': labelCtrl.text.trim(),
                                  'name': nameCtrl.text.trim(),
                                  'phone': phoneCtrl.text.trim(),
                                  'address': addressCtrl.text.trim(),
                                  'city': cityCtrl.text.trim(),
                                  'state': stateCtrl.text.trim(),
                                  'pincode': pincodeCtrl.text.trim(),
                                  'isDefault': isDefault,
                                };
                                Navigator.of(ctx).pop();
                                if (mounted) setState(() => _saving = true);
                                try {
                                  if (existing == null) {
                                    await sl<ApiClient>().post(ApiConstants.addresses, data: payload);
                                  } else {
                                    await sl<ApiClient>().put(
                                      '${ApiConstants.addresses}/${existing['id']}',
                                      data: payload,
                                    );
                                  }
                                  await _loadAddresses();
                                } catch (e) {
                                  if (!mounted) return;
                                  AppErrorHandler.show('Failed to save address. Please try again.');
                                } finally {
                                  if (mounted) setState(() => _saving = false);
                                }
                              },
                        child: Text(
                          formSaving
                              ? (existing == null ? 'Adding...' : 'Saving...')
                              : (existing == null ? 'Add Address' : 'Save Changes'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      _addressSheetOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _showAddressForm(),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 58),
                      const SizedBox(height: 8),
                      Text(
                        'No saved addresses yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAddresses,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
                    itemCount: _addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final a = _addresses[i];
                      final id = (a['id'] ?? '').toString();
                      final isDefault = a['isDefault'] == true;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    (a['label'] ?? 'Address').toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Default',
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('${a['name'] ?? ''} • ${a['phone'] ?? ''}'),
                              const SizedBox(height: 4),
                              Text(
                                '${a['address'] ?? ''}, ${a['city'] ?? ''}, ${a['state'] ?? ''} - ${a['pincode'] ?? ''}',
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: _saving ? null : () => _showAddressForm(existing: a),
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    label: const Text('Edit'),
                                  ),
                                  TextButton.icon(
                                    onPressed: (_saving || isDefault)
                                        ? null
                                        : () => _setDefault(id),
                                    icon: const Icon(Icons.check_circle_outline, size: 18),
                                    label: const Text('Set Default'),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: _saving ? null : () => _deleteAddress(id),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
