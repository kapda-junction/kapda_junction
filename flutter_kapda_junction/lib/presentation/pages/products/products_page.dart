import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/products/products_bloc.dart';
import '../../widgets/product/product_card.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../data/datasources/remote/home_remote_datasource.dart';
import '../../../domain/entities/category.dart';

class ProductsPage extends StatefulWidget {
  final String? categoryId;
  final String? initialSearch;

  const ProductsPage({super.key, this.categoryId, this.initialSearch});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final ProductsBloc _bloc;
  List<Category> _categories = [];
  bool _categoriesLoaded = false;
  String? _selectedCategoryId;
  String _selectedCategoryName = 'All Products';
  String? _filterSize;
  String? _filterColor;
  double? _filterMinPrice;
  double? _filterMaxPrice;

  void _reloadProducts() {
    _bloc.add(
      ProductsLoadRequested(
        category: _selectedCategoryId,
        search: widget.initialSearch,
        size: (_filterSize ?? '').trim().isEmpty ? null : _filterSize!.trim(),
        color:
            (_filterColor ?? '').trim().isEmpty ? null : _filterColor!.trim(),
        minPrice: _filterMinPrice,
        maxPrice: _filterMaxPrice,
      ),
    );
  }

  Future<void> _openVariantFilters() async {
    final sizeCtrl = TextEditingController(text: _filterSize ?? '');
    final colorCtrl = TextEditingController(text: _filterColor ?? '');
    final minCtrl = TextEditingController(
      text: _filterMinPrice != null ? _filterMinPrice!.toString() : '',
    );
    final maxCtrl = TextEditingController(
      text: _filterMaxPrice != null ? _filterMaxPrice!.toString() : '',
    );
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final inset = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + inset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter catalogue',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Match products that have a variant with this size and/or colour. Price in ₹.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sizeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Size (e.g. M, 32)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Colour',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Min ₹',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Max ₹',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      sizeCtrl.clear();
                      colorCtrl.clear();
                      minCtrl.clear();
                      maxCtrl.clear();
                    },
                    child: const Text('Clear fields'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (ok == true && mounted) {
      double? pMin = double.tryParse(minCtrl.text.trim());
      double? pMax = double.tryParse(maxCtrl.text.trim());
      setState(() {
        _filterSize = sizeCtrl.text.trim().isEmpty ? null : sizeCtrl.text.trim();
        _filterColor =
            colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim();
        _filterMinPrice = pMin;
        _filterMaxPrice = pMax;
      });
      _reloadProducts();
    }
    sizeCtrl.dispose();
    colorCtrl.dispose();
    minCtrl.dispose();
    maxCtrl.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    if (widget.categoryId != null) _selectedCategoryName = 'Filtered';
    _bloc = sl<ProductsBloc>();
    _reloadProducts();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await sl<HomeRemoteDataSource>().getCategoryTree();
      if (mounted) {
        setState(() {
          _categories = cats;
          _categoriesLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _categoriesLoaded = true);
    }
  }

  void _applyFilter(String? categoryId, String categoryName) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryName;
    });
    _reloadProducts();
    Navigator.of(context).pop(); // close drawer
  }

  SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(
    BuildContext context,
  ) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final width = size.width;

    if (width >= 1100) {
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.76,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      );
    }
    if (width >= 800) {
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      );
    }
    if (width >= 600 || isLandscape) {
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.66,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      );
    }
    return const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.56,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    );
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final productGridDelegate = _gridDelegate(context);
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerHighest,
        drawer: _CategoryDrawer(
          categories: _categories,
          loaded: _categoriesLoaded,
          selectedId: _selectedCategoryId,
          onSelect: _applyFilter,
        ),
        appBar: AppBar(
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              tooltip: 'Filter by category',
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Products',
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              if (_selectedCategoryId != null)
                Text(
                  _selectedCategoryName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune, color: Colors.white),
              tooltip: 'Size, colour, price',
              onPressed: _openVariantFilters,
            ),
            if (_selectedCategoryId != null)
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.accent),
                tooltip: 'Clear filter',
                onPressed: () => _applyFilter(null, 'All Products'),
              ),
          ],
        ),
        body: BlocBuilder<ProductsBloc, ProductsState>(
          builder: (context, state) {
            if (state is ProductsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProductsFailure) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, style: AppTypography.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reloadProducts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state is ProductsLoaded) {
              if (state.products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 56,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No products found',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _reloadProducts(),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: productGridDelegate,
                  itemCount: state.products.length,
                  itemBuilder: (_, i) =>
                      ProductCard(product: state.products[i]),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class _CategoryDrawer extends StatefulWidget {
  final List<Category> categories;
  final bool loaded;
  final String? selectedId;
  final void Function(String? id, String name) onSelect;

  const _CategoryDrawer({
    required this.categories,
    required this.loaded,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<_CategoryDrawer> createState() => _CategoryDrawerState();
}

class _CategoryDrawerState extends State<_CategoryDrawer> {
  String? _expandedCategoryId;

  @override
  void initState() {
    super.initState();
    // Auto-expand parent if a subcategory is selected
    if (widget.selectedId != null) {
      for (final cat in widget.categories) {
        if (cat.children.any((c) => c.id == widget.selectedId)) {
          _expandedCategoryId = cat.id;
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      width: 270,
      backgroundColor: colorScheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 20,
              right: 20,
            ),
            color: AppColors.primary,
            child: Row(
              children: [
                const Icon(
                  Icons.category_outlined,
                  color: AppColors.accent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Categories',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // All Products
          _AllTile(
            isSelected: widget.selectedId == null,
            onTap: () => widget.onSelect(null, 'All Products'),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Category tree
          Expanded(
            child: !widget.loaded
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : widget.categories.isEmpty
                ? Center(
                    child: Text(
                      'No categories',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: widget.categories.length,
                    itemBuilder: (_, i) {
                      final cat = widget.categories[i];
                      final isSelected = widget.selectedId == cat.id;
                      final isExpanded = _expandedCategoryId == cat.id;

                      if (cat.children.isEmpty) {
                        return _CategoryTile(
                          category: cat,
                          isSelected: isSelected,
                          indent: 0,
                          onTap: () => widget.onSelect(cat.id, cat.name),
                        );
                      }

                      // Has subcategories — expandable
                      return Column(
                        children: [
                          _CategoryTile(
                            category: cat,
                            isSelected: isSelected,
                            indent: 0,
                            trailing: AnimatedRotation(
                              turns: isExpanded ? 0.25 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _expandedCategoryId = isExpanded
                                    ? null
                                    : cat.id;
                              });
                              widget.onSelect(cat.id, cat.name);
                            },
                          ),
                          // Subcategories
                          AnimatedCrossFade(
                            firstChild: const SizedBox(width: double.infinity),
                            secondChild: Column(
                              children: cat.children
                                  .map(
                                    (sub) => _CategoryTile(
                                      category: sub,
                                      isSelected: widget.selectedId == sub.id,
                                      indent: 1,
                                      onTap: () =>
                                          widget.onSelect(sub.id, sub.name),
                                    ),
                                  )
                                  .toList(),
                            ),
                            crossFadeState: isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 220),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AllTile extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  const _AllTile({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: AppColors.accent.withAlpha(20),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.grid_view_rounded,
          size: 18,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      title: Text(
        'All Products',
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final int indent; // 0 = parent, 1 = subcategory
  final Widget? trailing;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.indent,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: AppColors.accent.withAlpha(20),
      contentPadding: EdgeInsets.only(
        left: indent == 1 ? 56.0 : 16.0,
        right: 12,
      ),
      leading: indent == 0
          ? Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? AppColors.accent.withAlpha(30)
                    : AppColors.border,
              ),
              child: category.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: category.image!,
                        fit: BoxFit.cover,
                        errorWidget: (context, error, stackTrace) =>
                            _fallbackIcon(),
                      ),
                    )
                  : _fallbackIcon(),
            )
          : null,
      title: Text(
        category.name,
        style: TextStyle(
          fontSize: indent == 0 ? 13 : 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
      trailing:
          trailing ??
          (isSelected
              ? const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.accent,
                )
              : null),
    );
  }

  Widget _fallbackIcon() => Icon(
    Icons.checkroom,
    size: 18,
    color: isSelected ? AppColors.accent : AppColors.textSecondary,
  );
}
