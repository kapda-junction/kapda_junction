import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/di/injection.dart';
import '../../../data/datasources/remote/product_datasource.dart';
import '../../../data/datasources/remote/category_datasource.dart';
import '../../../data/datasources/remote/options_datasource.dart';
import '../../../data/datasources/remote/upload_datasource.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/color_option.dart';

class ProductFormPage extends StatefulWidget {
  final String? productId;
  const ProductFormPage({super.key, this.productId});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _shopCodeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _compareCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _uploadingImages = false;

  // Category
  List<Category> _allCategories = [];
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;

  // Toggles
  bool _isActive = true;
  bool _isFeatured = false;

  // Images
  final List<String> _images = [];
  // colorId → uploaded URLs
  final Map<String, List<String>> _colorImages = {};
  final Map<String, bool> _uploadingColorImages = {};

  // Variants
  List<ColorOption> _colors = [];
  List<SizeOption> _sizes = [];
  final Set<String> _selColors = {};
  final Set<String> _selSizes = {};
  // stock[colorId][sizeId] = stock count
  final Map<String, Map<String, TextEditingController>> _stockCtrl = {};

  List<Category> get _topLevel =>
      _allCategories.where((c) => c.parentId == null).toList();

  List<Category> get _subcategories => _selectedCategoryId == null
      ? []
      : _allCategories.where((c) => c.parentId == _selectedCategoryId).toList();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        sl<CategoryDataSource>().getAll(),
        sl<OptionsDataSource>().getColors(),
        sl<OptionsDataSource>().getSizes(),
      ]);
      _allCategories = results[0] as List<Category>;
      _colors = results[1] as List<ColorOption>;
      _sizes = results[2] as List<SizeOption>;

      if (widget.productId != null) {
        final p = await sl<ProductDataSource>().getProduct(widget.productId!);
        _nameCtrl.text = p.name;
        _shopCodeCtrl.text = p.shopCode ?? '';
        _descCtrl.text = p.description ?? '';
        _priceCtrl.text = p.price.toStringAsFixed(0);
        _compareCtrl.text = p.compareAtPrice?.toStringAsFixed(0) ?? '';
        _isActive = p.isActive;
        _isFeatured = p.isFeatured;
        _images.addAll(p.images);

        // Resolve category vs subcategory
        if (p.categoryId != null) {
          final cat = _allCategories.where((c) => c.id == p.categoryId).firstOrNull;
          if (cat != null) {
            if (cat.parentId != null) {
              _selectedCategoryId = cat.parentId;
              _selectedSubcategoryId = cat.id;
            } else {
              _selectedCategoryId = cat.id;
            }
          }
        }

        // Restore color images (colorName → colorId)
        for (final entry in p.colorImages.entries) {
          final color = _colors.where((c) => c.name == entry.key).firstOrNull;
          if (color != null) _colorImages[color.id] = List.from(entry.value);
        }

        // Restore variant selections
        for (final v in p.variants) {
          final color = _colors.where((c) => c.name == v.color).firstOrNull;
          final size = _sizes.where((s) => s.name == v.size).firstOrNull;
          if (color != null) _selColors.add(color.id);
          if (size != null) _selSizes.add(size.id);
          if (color != null && size != null) {
            _stockCtrl.putIfAbsent(color.id, () => {});
            _stockCtrl[color.id]![size.id] =
                TextEditingController(text: v.stock.toString());
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _toggleColor(String id, bool selected) {
    setState(() {
      if (selected) {
        _selColors.add(id);
        _stockCtrl.putIfAbsent(id, () => {});
        _colorImages.putIfAbsent(id, () => []);
        for (final sId in _selSizes) {
          _stockCtrl[id]!.putIfAbsent(sId, () => TextEditingController(text: '1'));
        }
      } else {
        _selColors.remove(id);
        _stockCtrl.remove(id);
        _colorImages.remove(id);
        _uploadingColorImages.remove(id);
      }
    });
  }

  void _toggleSize(String id, bool selected) {
    setState(() {
      if (selected) {
        _selSizes.add(id);
        for (final cId in _selColors) {
          _stockCtrl.putIfAbsent(cId, () => {});
          _stockCtrl[cId]!.putIfAbsent(id, () => TextEditingController(text: '1'));
        }
      } else {
        _selSizes.remove(id);
        for (final cId in _selColors) {
          _stockCtrl[cId]?.remove(id);
        }
      }
    });
  }

  Future<List<XFile>?> _showSourceAndPick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Browse Gallery'),
                subtitle: const Text('Pick multiple images'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return null;
    final picker = ImagePicker();
    if (source == ImageSource.gallery) return picker.pickMultiImage(imageQuality: 85);
    final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    return img != null ? [img] : [];
  }

  Future<void> _pickImages() async {
    final picked = await _showSourceAndPick();
    if (picked == null || picked.isEmpty) return;
    setState(() => _uploadingImages = true);
    try {
      final upload = sl<UploadDataSource>();
      for (final img in picked) {
        final url = await upload.uploadProductImage(img.path);
        if (mounted) setState(() => _images.add(url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploadingImages = false);
    }
  }

  Future<void> _pickColorImages(String colorId) async {
    final picked = await _showSourceAndPick();
    if (picked == null || picked.isEmpty) return;
    setState(() => _uploadingColorImages[colorId] = true);
    try {
      final upload = sl<UploadDataSource>();
      _colorImages.putIfAbsent(colorId, () => []);
      for (final img in picked) {
        final url = await upload.uploadProductImage(img.path);
        if (mounted) setState(() => _colorImages[colorId]!.add(url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploadingColorImages[colorId] = false);
    }
  }

  List<Map<String, dynamic>> _buildVariants() {
    final list = <Map<String, dynamic>>[];
    for (final cId in _selColors) {
      final colorName = _colors.firstWhere((c) => c.id == cId).name;
      for (final sId in _selSizes) {
        final sizeName = _sizes.firstWhere((s) => s.id == sId).name;
        final stock = int.tryParse(_stockCtrl[cId]?[sId]?.text ?? '1') ?? 1;
        list.add({'color': colorName, 'size': sizeName, 'stock': stock});
      }
    }
    return list;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least one product image'),
      ));
      return;
    }
    setState(() => _saving = true);

    // Effective category = subcategory if selected, else parent
    final effectiveCategoryId = _selectedSubcategoryId ?? _selectedCategoryId;

    final shop = _shopCodeCtrl.text.trim();
    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'shopCode': shop.isEmpty ? null : shop.toUpperCase(),
      'description': _descCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text) ?? 0,
      if (_compareCtrl.text.isNotEmpty) 'compareAtPrice': double.tryParse(_compareCtrl.text),
      if (effectiveCategoryId != null) 'category': effectiveCategoryId,
      'isActive': _isActive,
      'isFeatured': _isFeatured,
      'images': _images,
      'colorImages': _selColors.map((cId) {
        final colorName = _colors.firstWhere((c) => c.id == cId).name;
        return {'color': colorName, 'images': _colorImages[cId] ?? []};
      }).toList(),
      'variants': _buildVariants(),
    };
    try {
      final ds = sl<ProductDataSource>();
      if (widget.productId != null) {
        await ds.updateProduct(widget.productId!, data);
      } else {
        await ds.createProduct(data);
      }
      if (mounted) context.go('/products');
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shopCodeCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _compareCtrl.dispose();
    for (final m in _stockCtrl.values) {
      for (final c in m.values) { c.dispose(); }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Add Product' : 'Edit Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products'),
        ),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Basic Info ─────────────────────────────────────────
                  _SectionHeader(title: 'Basic Info', icon: Icons.info_outline),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name *'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _shopCodeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Shop code (optional)',
                      hintText: 'e.g. A1B2 — 4–5 letters/digits, unique',
                      helperText: 'Search in Inventory by this code after offline sales',
                    ),
                    maxLength: 5,
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return null;
                      if (t.length < 4) return 'Min 4 characters';
                      if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(t)) {
                        return 'Letters and digits only';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    minLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Price (₹) *', prefixText: '₹ '),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _compareCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Compare at Price (₹)', prefixText: '₹ '),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Visible to customers'),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Featured'),
                        value: _isFeatured,
                        onChanged: (v) => setState(() => _isFeatured = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── Category ───────────────────────────────────────────
                  _SectionHeader(title: 'Category', icon: Icons.category_outlined),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category *'),
                    validator: (v) => v == null ? 'Select a category' : null,
                    items: [
                      const DropdownMenuItem<String>(
                          value: null, child: Text('-- Select --')),
                      ..._topLevel.map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) => setState(() {
                      _selectedCategoryId = v;
                      _selectedSubcategoryId = null;
                    }),
                  ),
                  if (_subcategories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubcategoryId,
                      decoration: const InputDecoration(labelText: 'Subcategory'),
                      items: [
                        const DropdownMenuItem<String>(
                            value: null, child: Text('-- None --')),
                        ..._subcategories.map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (v) => setState(() => _selectedSubcategoryId = v),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Images ─────────────────────────────────────────────
                  _SectionHeader(title: 'Images', icon: Icons.photo_library_outlined),
                  const SizedBox(height: 4),
                  Text(
                    'Select and upload multiple images. Product page shows a gallery; cards use a slider.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),

                  // Image thumbnails grid
                  if (_images.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length + (_uploadingImages ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          if (i == _images.length) {
                            return Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          }
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _images[i],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 100,
                                    color: cs.surfaceContainerHighest,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() => _images.removeAt(i)),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  if (_images.isNotEmpty) const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: _uploadingImages ? null : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(_uploadingImages ? 'Uploading…' : 'Choose Images'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Variants ───────────────────────────────────────────
                  _SectionHeader(
                    title: 'Variants (Color × Size + Stock)',
                    icon: Icons.grid_view_outlined,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select colors and sizes. Set stock per combo — 0 = sold out.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),

                  if (_colors.isEmpty && _sizes.isEmpty)
                    Text('No colors or sizes defined yet. Add them in Options.',
                        style: Theme.of(context).textTheme.bodySmall)
                  else ...[
                    // Colors checkboxes
                    if (_colors.isNotEmpty) ...[
                      Text('Colors (multi-select)',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _colors.map((c) {
                          final sel = _selColors.contains(c.id);
                          return FilterChip(
                            label: Text(c.name),
                            selected: sel,
                            onSelected: (v) => _toggleColor(c.id, v),
                            selectedColor: Theme.of(context).colorScheme.primaryContainer,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Per-color images
                      if (_selColors.isNotEmpty) ...[
                        Text('Images per Color',
                            style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Optional — if set, customers see color-specific images when they select that color.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        ..._selColors.map((cId) {
                          final colorName = _colors.firstWhere((c) => c.id == cId).name;
                          final imgs = _colorImages[cId] ?? [];
                          final uploading = _uploadingColorImages[cId] ?? false;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(colorName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: 80,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      ...imgs.asMap().entries.map((e) => Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Stack(children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              e.value,
                                              width: 80, height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 80,
                                                color: cs.surfaceContainerHighest,
                                                child: const Icon(Icons.broken_image),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 2, right: 2,
                                            child: GestureDetector(
                                              onTap: () => setState(() => _colorImages[cId]!.removeAt(e.key)),
                                              child: Container(
                                                width: 20, height: 20,
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                                              ),
                                            ),
                                          ),
                                        ]),
                                      )),
                                      if (uploading)
                                        Container(
                                          width: 80, height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            color: cs.surfaceContainerHighest,
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      GestureDetector(
                                        onTap: uploading ? null : () => _pickColorImages(cId),
                                        child: Container(
                                          width: 80, height: 80,
                                          margin: EdgeInsets.only(left: uploading ? 8.0 : 0.0),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: cs.outline),
                                          ),
                                          child: Icon(
                                            Icons.add_photo_alternate_outlined,
                                            color: uploading ? cs.outline : cs.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                      ],
                    ],

                    // Sizes checkboxes
                    if (_sizes.isNotEmpty) ...[
                      Text('Sizes (multi-select)',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _sizes.map((s) {
                          final sel = _selSizes.contains(s.id);
                          return FilterChip(
                            label: Text(s.name),
                            selected: sel,
                            onSelected: (v) => _toggleSize(s.id, v),
                            selectedColor: Theme.of(context).colorScheme.primaryContainer,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Stock grid
                    if (_selColors.isNotEmpty && _selSizes.isNotEmpty) ...[
                      Text('Stock per Color × Size',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      _StockGrid(
                        colors: _colors.where((c) => _selColors.contains(c.id)).toList(),
                        sizes: _sizes.where((s) => _selSizes.contains(s.id)).toList(),
                        controllers: _stockCtrl,
                      ),
                    ],
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ── Section header widget ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(icon, size: 18, color: cs.primary),
      const SizedBox(width: 8),
      Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(width: 8),
      Expanded(child: Divider(color: cs.outline)),
    ]);
  }
}

// ── Stock grid ───────────────────────────────────────────────────────────────

class _StockGrid extends StatelessWidget {
  final List<ColorOption> colors;
  final List<SizeOption> sizes;
  final Map<String, Map<String, TextEditingController>> controllers;

  const _StockGrid({
    required this.colors,
    required this.sizes,
    required this.controllers,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const colW = 80.0;
    const labelW = 80.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(children: [
            SizedBox(
              width: labelW,
              child: Text('Color',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            ...sizes.map((s) => SizedBox(
                  width: colW,
                  child: Text(s.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                )),
          ]),
          const SizedBox(height: 6),

          // Data rows
          ...colors.map((c) {
            controllers.putIfAbsent(c.id, () => {});
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                SizedBox(
                  width: labelW,
                  child: Text(c.name,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                ...sizes.map((s) {
                  controllers[c.id]!.putIfAbsent(
                      s.id, () => TextEditingController(text: '1'));
                  return SizedBox(
                    width: colW,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextField(
                        controller: controllers[c.id]![s.id],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: cs.outline),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ]),
            );
          }),
        ],
      ),
    );
  }
}
