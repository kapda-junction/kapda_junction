import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/remote/notification_datasource.dart';
import '../../../data/datasources/remote/product_datasource.dart';
import '../../../data/datasources/remote/upload_datasource.dart';
import '../../../domain/entities/product.dart';
import '../../widgets/common/admin_drawer.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _dataCtrl = TextEditingController();
  final _userSearchCtrl = TextEditingController();

  final _selectedUserIds = <String>{};

  List<Map<String, dynamic>> _audienceUsers = [];
  List<Product> _products = [];
  String _audienceType = 'broadcast';
  String? _selectedProductId;
  bool _loadingUsers = true;
  bool _loadingProducts = true;
  bool _uploadingImage = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadAudience();
    _loadProducts();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageCtrl.dispose();
    _dataCtrl.dispose();
    _userSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAudience({String? search}) async {
    setState(() => _loadingUsers = true);
    try {
      final users = await sl<NotificationDataSource>().getAudience(search: search, limit: 100);
      _audienceUsers = users;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load users for notification audience')),
      );
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final result = await sl<ProductDataSource>().getProducts(page: 1, limit: 200);
      _products = result.products;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load products')),
      );
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
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

  Product? get _selectedProduct {
    if (_selectedProductId == null) return null;
    for (final p in _products) {
      if (p.id == _selectedProductId) return p;
    }
    return null;
  }

  void _onProductSelected(String? productId) {
    setState(() => _selectedProductId = productId);
    final p = _selectedProduct;
    if (p == null) return;
    if (_titleCtrl.text.trim().isEmpty) {
      _titleCtrl.text = 'New arrival: ${p.name}';
    }
    if (_bodyCtrl.text.trim().isEmpty) {
      _bodyCtrl.text = '${p.name} is now available at ${PriceFormatter.format(p.price)}. Tap to view.';
    }
    if (_imageCtrl.text.trim().isEmpty && p.images.isNotEmpty) {
      _imageCtrl.text = p.images.first;
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (picked == null) return;
    setState(() => _uploadingImage = true);
    try {
      final url = await sl<UploadDataSource>().uploadBannerImage(picked.path);
      _imageCtrl.text = url;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and body are required')),
      );
      return;
    }
    if (_audienceType == 'users' && _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one user for specific audience')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final data = _parseDataJson();
      final res = await sl<NotificationDataSource>().send(
        audienceType: _audienceType,
        userIds: _audienceType == 'users' ? _selectedUserIds.toList() : null,
        productId: _selectedProductId,
        title: title,
        body: body,
        data: data,
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
      );
      if (!mounted) return;
      final sent = res['sentCount'] ?? 0;
      final fail = res['failureCount'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Push sent: $sent success, $fail failed')),
      );
      setState(() {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _imageCtrl.clear();
        _dataCtrl.clear();
        _selectedProductId = null;
        _selectedUserIds.clear();
      });
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
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersWithToken = _audienceUsers.where((u) => (u['hasToken'] == true)).toList();
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(title: const Text('Notifications')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Push Notifications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Broadcast to all users, or target specific users. You can attach product and image.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'broadcast', icon: Icon(Icons.campaign_outlined), label: Text('Broadcast')),
                ButtonSegment(value: 'users', icon: Icon(Icons.group_outlined), label: Text('Specific Users')),
              ],
              selected: {_audienceType},
              onSelectionChanged: (s) => setState(() => _audienceType = s.first),
            ),
            if (_audienceType == 'users') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userSearchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search users by name/email',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _loadingUsers ? null : () => _loadAudience(search: _userSearchCtrl.text),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Load'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 210,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _loadingUsers
                    ? const Center(child: CircularProgressIndicator())
                    : usersWithToken.isEmpty
                        ? const Center(child: Text('No token-enabled users found'))
                        : ListView.separated(
                            itemCount: usersWithToken.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final u = usersWithToken[i];
                              final id = (u['id'] ?? '').toString();
                              final selected = _selectedUserIds.contains(id);
                              return CheckboxListTile(
                                dense: true,
                                value: selected,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedUserIds.add(id);
                                    } else {
                                      _selectedUserIds.remove(id);
                                    }
                                  });
                                },
                                title: Text('${u['name'] ?? 'User'} (${u['email'] ?? ''})'),
                                subtitle: Text('Tokens: ${u['tokenCount'] ?? 0}'),
                                controlAffinity: ListTileControlAffinity.leading,
                              );
                            },
                          ),
              ),
              const SizedBox(height: 4),
              Text('Selected users: ${_selectedUserIds.length}'),
            ],
            const SizedBox(height: 16),
            if (_loadingProducts)
              const LinearProgressIndicator(minHeight: 2)
            else
              DropdownButtonFormField<String>(
                value: _selectedProductId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Attach Product (optional)',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                hint: const Text('No product attached'),
                items: _products
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p.id,
                        child: Text('${p.name} - ${PriceFormatter.format(p.price)}'),
                      ),
                    )
                    .toList(),
                onChanged: _onProductSelected,
              ),
            if (_selectedProductId != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _selectedProductId = null),
                  icon: const Icon(Icons.close),
                  label: const Text('Remove product'),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Notification Title *',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bodyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notification Body *',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.message_outlined),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Image URL (optional)',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _uploadingImage ? null : _pickAndUploadImage,
                  icon: _uploadingImage
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: const Text('Upload'),
                )
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dataCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Data JSON (optional)',
                hintText: '{"type":"product","campaign":"new-arrival"}',
                prefixIcon: Icon(Icons.data_object),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_sending ? 'Sending...' : 'Send Notification'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
