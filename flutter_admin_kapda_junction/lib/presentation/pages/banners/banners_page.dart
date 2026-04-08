import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/remote/product_datasource.dart';
import '../../../data/datasources/remote/upload_datasource.dart';
import '../../../domain/entities/product.dart';
import '../../bloc/banners/banners_bloc.dart';
import '../../widgets/common/admin_drawer.dart';
import '../../../domain/entities/banner.dart';

class BannersPage extends StatelessWidget {
  const BannersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BannersBloc>()..add(BannersLoadRequested()),
      child: const _BannersView(),
    );
  }
}

class _BannersView extends StatefulWidget {
  const _BannersView();

  @override
  State<_BannersView> createState() => _BannersViewState();
}

class _BannersViewState extends State<_BannersView> {
  Future<void> _showForm(BuildContext context, {AppBanner? banner}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BannerFormDialog(
        initialBanner: banner,
        onSave: (data) {
          context.read<BannersBloc>().add(
                BannerSaveRequested(id: banner?.id, data: data),
              );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text('Delete this banner? This cannot be undone.'),
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
      context.read<BannersBloc>().add(BannerDeleteRequested(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Banners'),
        actions: [
          FilledButton.icon(
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Banner'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: BlocConsumer<BannersBloc, BannersState>(
        listener: (context, state) {
          if (state is BannerSaveSuccess) {
            context.read<BannersBloc>().add(BannersLoadRequested());
          } else if (state is BannersFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is BannersLoading) return const Center(child: CircularProgressIndicator());
          if (state is BannersSaving) return const Center(child: CircularProgressIndicator());
          if (state is BannersFailure) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(state.message),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => context.read<BannersBloc>().add(BannersLoadRequested()), child: const Text('Retry')),
            ]));
          }
          if (state is BannersLoaded) {
            if (state.banners.isEmpty) return const Center(child: Text('No banners yet.'));
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: state.banners.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final b = state.banners[i];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(b.image, width: 64, height: 40, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40)),
                  ),
                  title: Text('Banner #${i + 1}'),
                  subtitle: Text('Sort: ${b.sortOrder} · ${b.isActive ? "Active" : "Inactive"}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Switch(
                      value: b.isActive,
                      onChanged: (v) => context.read<BannersBloc>().add(
                            BannerSaveRequested(
                              id: b.id,
                              data: {'isActive': v},
                            ),
                          ),
                    ),
                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showForm(context, banner: b)),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                      onPressed: () => _confirmDelete(context, b.id),
                    ),
                  ]),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _BannerFormDialog extends StatefulWidget {
  final AppBanner? initialBanner;
  final ValueChanged<Map<String, dynamic>> onSave;

  const _BannerFormDialog({
    required this.initialBanner,
    required this.onSave,
  });

  @override
  State<_BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<_BannerFormDialog> {
  final _imageCtrl = TextEditingController();
  final _sortCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  bool _isActive = true;
  bool _loadingProducts = true;
  bool _uploadingImage = false;
  bool _saving = false;

  List<Product> _allProducts = [];
  Set<String> _selectedProductIds = <String>{};

  List<Product> get _filteredProducts {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _allProducts;
    return _allProducts
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.categoryName ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final b = widget.initialBanner;
    _imageCtrl.text = b?.image ?? '';
    _sortCtrl.text = (b?.sortOrder ?? 0).toString();
    _isActive = b?.isActive ?? true;
    _selectedProductIds = b?.products.map((e) => e.id).toSet() ?? <String>{};
    _searchCtrl.addListener(() => setState(() {}));
    _loadProducts();
  }

  @override
  void dispose() {
    _imageCtrl.dispose();
    _sortCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final result = await sl<ProductDataSource>().getProducts(page: 1, limit: 200);
      _allProducts = result.products;
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (picked == null) return;
    setState(() => _uploadingImage = true);
    try {
      final url = await sl<UploadDataSource>().uploadBannerImage(picked.path);
      _imageCtrl.text = url;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner image uploaded')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _toggleProduct(String productId, bool selected) {
    final next = {..._selectedProductIds};
    if (selected) {
      if (next.length >= 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Max 4 products allowed on a banner')),
        );
        return;
      }
      next.add(productId);
    } else {
      next.remove(productId);
    }
    setState(() => _selectedProductIds = next);
  }

  void _save() {
    final image = _imageCtrl.text.trim();
    if (image.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner image is required')),
      );
      return;
    }
    final body = <String, dynamic>{
      'image': image,
      'products': _selectedProductIds.toList(),
      'sortOrder': int.tryParse(_sortCtrl.text.trim()) ?? 0,
      'isActive': _isActive,
    };
    setState(() => _saving = true);
    widget.onSave(body);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialBanner != null;

    return AlertDialog(
      title: Text(editing ? 'Edit Banner' : 'Add Banner'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Banner Image *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploadingImage ? null : _pickAndUploadImage,
                      icon: _uploadingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: Text(_uploadingImage ? 'Uploading...' : 'Choose from gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              if (_imageCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _imageCtrl.text.trim(),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Text('Image preview unavailable'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Products (max 4)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Select products to show as clickable patches on banner.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 190,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _loadingProducts
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredProducts.isEmpty
                        ? const Center(child: Text('No products found'))
                        : ListView.separated(
                            itemCount: _filteredProducts.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final p = _filteredProducts[i];
                              final selected = _selectedProductIds.contains(p.id);
                              return CheckboxListTile(
                                dense: true,
                                value: selected,
                                onChanged: (v) => _toggleProduct(p.id, v ?? false),
                                title: Text('${p.name} - ${PriceFormatter.format(p.price)}'),
                                secondary: p.images.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          p.images.first,
                                          width: 38,
                                          height: 38,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.image_not_supported_outlined),
                                        ),
                                      )
                                    : const Icon(Icons.image_outlined),
                                controlAffinity: ListTileControlAffinity.leading,
                              );
                            },
                          ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selected: ${_selectedProductIds.length}/4',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sortCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sort Order',
                        prefixIcon: Icon(Icons.sort),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (_saving || _uploadingImage) ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
