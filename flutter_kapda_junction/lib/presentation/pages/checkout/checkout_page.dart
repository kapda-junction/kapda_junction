import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/orders/orders_bloc.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../domain/repositories/order_repository.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  late final Razorpay _razorpay;
  late final OrdersBloc _ordersBloc;
  List<Map<String, dynamic>> _savedAddresses = [];
  String? _selectedAddressId;
  bool _loadingAddressBook = false;

  final _couponCtrl = TextEditingController();
  Map<String, dynamic>? _couponPreview;
  String? _appliedCode;
  bool _couponLoading = false;
  String? _couponCartFingerprint;
  String? _pendingMongoOrderId;

  String _cartFingerprint(CartState s) =>
      s.items.map((i) => '${i.variantKey}:${i.quantity}').join('|');

  @override
  void initState() {
    super.initState();
    _ordersBloc = sl<OrdersBloc>();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    _nameCtrl.text    = prefs.getString('addr_name')    ?? '';
    _phoneCtrl.text   = prefs.getString('addr_phone')   ?? '';
    _addressCtrl.text = prefs.getString('addr_address') ?? '';
    _cityCtrl.text    = prefs.getString('addr_city')    ?? '';
    _stateCtrl.text   = prefs.getString('addr_state')   ?? '';
    _pincodeCtrl.text = prefs.getString('addr_pincode') ?? '';

    final hasLocal = _nameCtrl.text.trim().isNotEmpty &&
        _phoneCtrl.text.trim().isNotEmpty &&
        _addressCtrl.text.trim().isNotEmpty &&
        _cityCtrl.text.trim().isNotEmpty &&
        _stateCtrl.text.trim().isNotEmpty &&
        _pincodeCtrl.text.trim().isNotEmpty;
    if (!hasLocal) {
      await _loadDefaultAddressFromServer();
    }
    await _loadAddressBookFromServer();
  }

  Future<void> _loadDefaultAddressFromServer() async {
    try {
      final res = await sl<ApiClient>().get(ApiConstants.addresses);
      final data = Map<String, dynamic>.from(res.data as Map);
      final addresses = (data['addresses'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (addresses.isEmpty) return;
      final def = addresses.firstWhere(
        (a) => a['isDefault'] == true,
        orElse: () => addresses.first,
      );
      _nameCtrl.text = (def['name'] ?? '').toString();
      _phoneCtrl.text = (def['phone'] ?? '').toString();
      _addressCtrl.text = (def['address'] ?? '').toString();
      _cityCtrl.text = (def['city'] ?? '').toString();
      _stateCtrl.text = (def['state'] ?? '').toString();
      _pincodeCtrl.text = (def['pincode'] ?? '').toString();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadAddressBookFromServer() async {
    setState(() => _loadingAddressBook = true);
    try {
      final res = await sl<ApiClient>().get(ApiConstants.addresses);
      final data = Map<String, dynamic>.from(res.data as Map);
      final addresses = (data['addresses'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) return;
      _savedAddresses = addresses;
      if (_selectedAddressId == null && addresses.isNotEmpty) {
        final def = addresses.firstWhere(
          (a) => a['isDefault'] == true,
          orElse: () => addresses.first,
        );
        _selectedAddressId = (def['id'] ?? '').toString();
      }
      setState(() {});
    } catch (_) {
      // Keep manual checkout usable even if address book request fails.
    } finally {
      if (mounted) setState(() => _loadingAddressBook = false);
    }
  }

  void _applyAddress(Map<String, dynamic> a) {
    _selectedAddressId = (a['id'] ?? '').toString();
    _nameCtrl.text = (a['name'] ?? '').toString();
    _phoneCtrl.text = (a['phone'] ?? '').toString();
    _addressCtrl.text = (a['address'] ?? '').toString();
    _cityCtrl.text = (a['city'] ?? '').toString();
    _stateCtrl.text = (a['state'] ?? '').toString();
    _pincodeCtrl.text = (a['pincode'] ?? '').toString();
  }

  Future<void> _showAddAddressSheet() async {
    final formKey = GlobalKey<FormState>();
    final labelCtrl = TextEditingController(text: 'Home');
    final nameCtrl = TextEditingController(text: _nameCtrl.text.trim());
    final phoneCtrl = TextEditingController(text: _phoneCtrl.text.trim());
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final pincodeCtrl = TextEditingController();
    bool isDefault = _savedAddresses.isEmpty;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
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
                    'Add New Address',
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
                    onChanged: saving ? null : (v) => setSheetState(() => isDefault = v),
                    title: const Text('Set as default address'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => saving = true);
                              try {
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
                                final res = await sl<ApiClient>().post(ApiConstants.addresses, data: payload);
                                final map = Map<String, dynamic>.from(res.data as Map);
                                final created = Map<String, dynamic>.from(map['address'] as Map? ?? {});
                                if (!mounted) return;
                                Navigator.of(ctx).pop();
                                await _loadAddressBookFromServer();
                                if (created.isNotEmpty) {
                                  setState(() => _applyAddress(created));
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to add address: $e')),
                                );
                                if (ctx.mounted) setSheetState(() => saving = false);
                              }
                            },
                      child: Text(saving ? 'Saving...' : 'Save Address'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    labelCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    pincodeCtrl.dispose();
  }

  Future<void> _showAddressSelector() async {
    await _loadAddressBookFromServer();
    if (!mounted) return;
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Other Address',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (_savedAddresses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No saved addresses. Add one to continue.'),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _savedAddresses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final a = _savedAddresses[i];
                      final id = (a['id'] ?? '').toString();
                      final active = id == _selectedAddressId;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Radio<bool>(
                          value: true,
                          groupValue: active,
                          onChanged: (_) => Navigator.of(ctx).pop(a),
                        ),
                        title: Text('${a['label'] ?? 'Address'}${a['isDefault'] == true ? ' (Default)' : ''}'),
                        subtitle: Text(
                          '${a['address'] ?? ''}, ${a['city'] ?? ''}, ${a['state'] ?? ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(ctx).pop(a),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showAddAddressSheet();
                      },
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Add New Address'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _applyAddress(selected));
    }
  }

  Future<void> _saveAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('addr_name',    _nameCtrl.text.trim());
    await prefs.setString('addr_phone',   _phoneCtrl.text.trim());
    await prefs.setString('addr_address', _addressCtrl.text.trim());
    await prefs.setString('addr_city',    _cityCtrl.text.trim());
    await prefs.setString('addr_state',   _stateCtrl.text.trim());
    await prefs.setString('addr_pincode', _pincodeCtrl.text.trim());
  }

  @override
  void dispose() {
    _razorpay.clear();
    _ordersBloc.close();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    final cartState = context.read<CartBloc>().state;
    if (cartState.isEmpty) return;

    final items = cartState.items
        .map(
          (i) => {
            'product': i.product.id,
            'name': i.product.name,
            'price': i.product.price,
            'quantity': i.quantity,
            'size': i.selectedSize,
            'color': i.selectedColor,
          },
        )
        .toList();

    setState(() => _couponLoading = true);
    try {
      final res = await sl<ApiClient>().post(
        ApiConstants.couponValidate,
        data: {'items': items, 'couponCode': code},
      );
      if (!mounted) return;
      final data = Map<String, dynamic>.from(res.data as Map);
      setState(() {
        _couponLoading = false;
        _couponPreview = data;
        _appliedCode = code.toUpperCase();
        _couponCartFingerprint = _cartFingerprint(cartState);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon applied'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _couponLoading = false;
        _couponPreview = null;
        _appliedCode = null;
        _couponCartFingerprint = null;
      });
      String msg = 'Could not apply coupon';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) msg = d['message'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  void _clearCoupon() {
    setState(() {
      _couponPreview = null;
      _appliedCode = null;
      _couponCartFingerprint = null;
      _couponCtrl.clear();
    });
  }

  double _checkoutTotal(CartState cartState) {
    if (_couponPreview != null && _couponCartFingerprint == _cartFingerprint(cartState)) {
      return (_couponPreview!['total'] as num).toDouble();
    }
    return cartState.totalPrice;
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    unawaited(_verifyPaymentAndFinish(response));
  }

  Future<void> _verifyPaymentAndFinish(PaymentSuccessResponse response) async {
    final mongoId = _pendingMongoOrderId;
    final paymentId = response.paymentId ?? '';
    final rzOrderId = response.orderId ?? '';
    final signature = response.signature ?? '';

    if (mongoId == null ||
        mongoId.isEmpty ||
        paymentId.isEmpty ||
        rzOrderId.isEmpty ||
        signature.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not confirm payment with the server. Check My Orders or contact support.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!mounted) return;
    final rootNav = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Confirming payment…'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final repo = sl<OrderRepository>();
    final result = await repo.verifyPayment({
      'orderId': mongoId,
      'razorpayOrderId': rzOrderId,
      'razorpayPaymentId': paymentId,
      'razorpaySignature': signature,
    });

    if (mounted && rootNav.canPop()) rootNav.pop();

    if (!mounted) return;
    result.fold(
      (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.error),
        );
      },
      (_) {
        _pendingMongoOrderId = null;
        context.read<CartBloc>().add(CartCleared());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/orders');
      },
    );
  }

  void _onPaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {}

  void _openRazorpay(Map<String, dynamic> paymentData) {
    final authState = context.read<AuthBloc>().state;
    final email = authState is AuthAuthenticated ? authState.user.email : '';
    final name = authState is AuthAuthenticated ? authState.user.name : '';

    _razorpay.open({
      'key': AppConstants.razorpayKeyId,
      'amount': paymentData['amount'],
      'order_id': paymentData['razorpayOrderId'],
      'name': 'Kapda Junction',
      'description': 'Order Payment',
      'prefill': {'name': name, 'email': email, 'contact': _phoneCtrl.text},
      'theme': {'color': '#F59E0B'},
    });
  }

  void _placeOrder() {
    if (!_formKey.currentState!.validate()) return;
    final cartState = context.read<CartBloc>().state;
    if (cartState.isEmpty) return;
    _saveAddress(); // persist for next checkout

    final items = cartState.items
        .map(
          (i) => {
            'product': i.product.id,
            'name': i.product.name,
            'price': i.product.price,
            'quantity': i.quantity,
            'size': i.selectedSize,
            'color': i.selectedColor,
          },
        )
        .toList();

    final body = <String, dynamic>{
      'items': items,
      'shippingAddress': {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
      },
    };
    if (_appliedCode != null &&
        _couponCartFingerprint == _cartFingerprint(cartState)) {
      body['couponCode'] = _appliedCode;
    }

    _ordersBloc.add(OrderPaymentInitiated(body));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return BlocProvider.value(
      value: _ordersBloc,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerHighest,
        appBar: AppBar(
          title: Text(
            'Checkout',
            style: AppTypography.headlineMedium.copyWith(color: Colors.white),
          ),
        ),
        body: BlocListener<CartBloc, CartState>(
          listenWhen: (prev, cur) => _cartFingerprint(prev) != _cartFingerprint(cur),
          listener: (context, cartState) {
            if (_appliedCode != null) _clearCoupon();
          },
          child: BlocConsumer<OrdersBloc, OrdersState>(
            listener: (context, state) {
              if (state is OrderPaymentReady) {
                _pendingMongoOrderId = state.paymentData['orderId']?.toString();
                _openRazorpay(state.paymentData);
              }
              if (state is OrdersFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              final cartState = context.watch<CartBloc>().state;
              final payTotal = _checkoutTotal(cartState);
              final showBreakdown = _couponPreview != null &&
                  _couponCartFingerprint == _cartFingerprint(cartState);

              return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shipping Address', style: textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _loadingAddressBook ? null : _showAddressSelector,
                          icon: _loadingAddressBook
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.location_on_outlined, size: 18),
                          label: const Text('Select Other Address'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => v!.isNotEmpty ? null : 'Required',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                      validator: (v) =>
                          v!.length >= 10 ? null : 'Enter valid phone',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(labelText: 'Address'),
                      maxLines: 2,
                      validator: (v) => v!.isNotEmpty ? null : 'Required',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'City',
                            ),
                            validator: (v) => v!.isNotEmpty ? null : 'Required',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stateCtrl,
                            decoration: const InputDecoration(
                              labelText: 'State',
                            ),
                            validator: (v) => v!.isNotEmpty ? null : 'Required',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pincodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Pincode'),
                      validator: (v) =>
                          v!.length == 6 ? null : '6-digit pincode',
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text('Order Summary', style: textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    ...cartState.items.map(
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${i.product.name} × ${i.quantity}',
                                style: AppTypography.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              PriceFormatter.format(i.totalPrice),
                              style: AppTypography.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                    Text('Promo code', style: textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Enter code',
                              isDense: true,
                            ),
                            enabled: !showBreakdown && state is! OrdersLoading,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (showBreakdown)
                          TextButton(
                            onPressed: state is OrdersLoading ? null : _clearCoupon,
                            child: const Text('Remove'),
                          )
                        else
                          FilledButton.tonal(
                            onPressed: (state is OrdersLoading || _couponLoading)
                                ? null
                                : _applyCoupon,
                            child: _couponLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Apply'),
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (showBreakdown) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: textTheme.bodyLarge),
                          Text(
                            PriceFormatter.format(
                              (_couponPreview!['subtotal'] as num).toDouble(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Discount ($_appliedCode)',
                            style: textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                          Text(
                            '− ${PriceFormatter.format((_couponPreview!['discountAmount'] as num).toDouble())}',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: textTheme.headlineSmall),
                        Text(
                          PriceFormatter.format(payTotal),
                          style: AppTypography.price,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state is OrdersLoading ? null : _placeOrder,
                        child: state is OrdersLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Pay ${PriceFormatter.format(payTotal)}',
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Secured by Razorpay',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
            },
          ),
        ),
      ),
    );
  }
}
