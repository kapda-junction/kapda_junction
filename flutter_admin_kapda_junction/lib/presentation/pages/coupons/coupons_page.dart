import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/coupon.dart';
import '../../bloc/coupons/coupons_bloc.dart';
import '../../widgets/common/admin_drawer.dart';

class CouponsPage extends StatelessWidget {
  const CouponsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CouponsBloc>()..add(CouponsLoadRequested()),
      child: const _CouponsView(),
    );
  }
}

class _CouponsView extends StatelessWidget {
  const _CouponsView();

  Future<void> _showForm(BuildContext context, {Coupon? coupon}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CouponFormDialog(
        initial: coupon,
        onSave: (data) {
          context.read<CouponsBloc>().add(
                CouponSaveRequested(id: coupon?.id, data: data),
              );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete coupon'),
        content: const Text('Remove this coupon? Existing orders are unchanged.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<CouponsBloc>().add(CouponDeleteRequested(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Coupons & offers'),
        actions: [
          FilledButton.icon(
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New coupon'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: BlocConsumer<CouponsBloc, CouponsState>(
        listener: (context, state) {
          if (state is CouponSaveSuccess) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            context.read<CouponsBloc>().add(CouponsLoadRequested());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coupon saved')),
            );
          } else if (state is CouponsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is CouponsLoading) return const Center(child: CircularProgressIndicator());
          if (state is CouponsSaving) return const Center(child: CircularProgressIndicator());
          if (state is CouponsFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          context.read<CouponsBloc>().add(CouponsLoadRequested()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final list = state is CouponsLoaded ? state.coupons : <Coupon>[];

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('No coupons yet'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _showForm(context),
                    child: const Text('Create coupon'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<CouponsBloc>().add(CouponsLoadRequested()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = list[i];
                final valueLabel = c.type == 'percentage' ? '${c.value}% off' : '₹${c.value} off';
                return Card(
                  child: ListTile(
                    title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      [
                        valueLabel,
                        if (c.minCartValue > 0) 'Min cart ₹${c.minCartValue}',
                        if (c.firstOrderOnly) 'First order only',
                        if (c.usageLimitTotal != null) 'Limit ${c.usedCount}/${c.usageLimitTotal}',
                        if (!c.isActive) 'Inactive',
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showForm(context, coupon: c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(context, c.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CouponFormDialog extends StatefulWidget {
  final Coupon? initial;
  final void Function(Map<String, dynamic> data) onSave;

  const _CouponFormDialog({this.initial, required this.onSave});

  @override
  State<_CouponFormDialog> createState() => _CouponFormDialogState();
}

class _CouponFormDialogState extends State<_CouponFormDialog> {
  late final TextEditingController _code;
  late final TextEditingController _desc;
  late final TextEditingController _value;
  late final TextEditingController _minCart;
  late final TextEditingController _maxDisc;
  late final TextEditingController _limitTotal;
  late final TextEditingController _limitPerUser;
  late final TextEditingController _restrictUser;
  late final TextEditingController _categoryIds;
  late final TextEditingController _productIds;
  late String _type;
  late bool _firstOnly;
  late bool _active;
  DateTime? _starts;
  DateTime? _ends;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _code = TextEditingController(text: c?.code ?? '');
    _desc = TextEditingController(text: c?.description ?? '');
    _value = TextEditingController(text: c != null ? c.value.toString() : '');
    _minCart = TextEditingController(text: c != null ? c.minCartValue.toString() : '0');
    _maxDisc = TextEditingController(
      text: c?.maxDiscountAmount != null ? c!.maxDiscountAmount!.toString() : '',
    );
    _limitTotal = TextEditingController(
      text: c?.usageLimitTotal != null ? c!.usageLimitTotal.toString() : '',
    );
    _limitPerUser = TextEditingController(
      text: c != null ? c.usageLimitPerUser.toString() : '1',
    );
    _restrictUser = TextEditingController(text: c?.restrictedUserId ?? '');
    _categoryIds = TextEditingController(text: c?.categoryIds.join(', ') ?? '');
    _productIds = TextEditingController(text: c?.productIds.join(', ') ?? '');
    _type = c?.type ?? 'percentage';
    _firstOnly = c?.firstOrderOnly ?? false;
    _active = c?.isActive ?? true;
    _starts = c?.startsAt;
    _ends = c?.endsAt;
  }

  @override
  void dispose() {
    _code.dispose();
    _desc.dispose();
    _value.dispose();
    _minCart.dispose();
    _maxDisc.dispose();
    _limitTotal.dispose();
    _limitPerUser.dispose();
    _restrictUser.dispose();
    _categoryIds.dispose();
    _productIds.dispose();
    super.dispose();
  }

  List<String> _splitIds(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _submit() {
    final val = double.tryParse(_value.text);
    if (_code.text.trim().isEmpty || val == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code and value are required')),
      );
      return;
    }

    final data = <String, dynamic>{
      'code': _code.text.trim(),
      'description': _desc.text.trim(),
      'type': _type,
      'value': val,
      'minCartValue': double.tryParse(_minCart.text) ?? 0,
      'maxDiscountAmount': _maxDisc.text.trim().isEmpty
          ? null
          : double.tryParse(_maxDisc.text.trim()),
      'firstOrderOnly': _firstOnly,
      'usageLimitTotal': _limitTotal.text.trim().isEmpty
          ? null
          : int.tryParse(_limitTotal.text.trim()),
      'usageLimitPerUser': int.tryParse(_limitPerUser.text) ?? 1,
      'restrictedUser': _restrictUser.text.trim().isEmpty ? null : _restrictUser.text.trim(),
      'categoryIds': _splitIds(_categoryIds.text),
      'productIds': _splitIds(_productIds.text),
      'startsAt': _starts?.toUtc().toIso8601String(),
      'endsAt': _ends?.toUtc().toIso8601String(),
      'isActive': _active,
    };

    widget.onSave(data);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'New coupon' : 'Edit coupon'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _code,
                decoration: const InputDecoration(labelText: 'Code (e.g. SAVE10)', hintText: 'SAVE10'),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 8),
              TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Discount type'),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed amount (₹)')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'percentage'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _value,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _type == 'percentage' ? 'Percent off' : 'Amount off (₹)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _minCart,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Min eligible cart (₹)',
                  helperText: 'Applies to eligible items only when categories/products set',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _maxDisc,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Max discount (₹, optional)',
                  helperText: 'Caps percentage discounts',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('First order only'),
                value: _firstOnly,
                onChanged: (v) => setState(() => _firstOnly = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _limitTotal,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total uses limit (optional)',
                ),
              ),
              TextField(
                controller: _limitPerUser,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Uses per customer'),
              ),
              TextField(
                controller: _restrictUser,
                decoration: const InputDecoration(
                  labelText: 'Specific user ID (optional)',
                  helperText: 'Mongo user _id for private codes',
                ),
              ),
              TextField(
                controller: _categoryIds,
                decoration: const InputDecoration(
                  labelText: 'Category IDs (comma-separated, optional)',
                ),
              ),
              TextField(
                controller: _productIds,
                decoration: const InputDecoration(
                  labelText: 'Product IDs (comma-separated, optional)',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _starts ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _starts = d);
                      },
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(_starts == null
                          ? 'Start date'
                          : DateFormatter.formatDate(_starts!.toIso8601String())),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _ends ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _ends = d);
                      },
                      icon: const Icon(Icons.event_available, size: 18),
                      label: Text(_ends == null
                          ? 'End date'
                          : DateFormatter.formatDate(_ends!.toIso8601String())),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => setState(() {
                  _starts = null;
                  _ends = null;
                }),
                child: const Text('Clear dates'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
