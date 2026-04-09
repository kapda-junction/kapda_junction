import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/injection.dart';
import '../../bloc/products/products_bloc.dart';
import '../../widgets/common/admin_drawer.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductsBloc>()..add(const ProductsLoadRequested()),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatefulWidget {
  const _ProductsView();
  @override
  State<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<_ProductsView> {
  final _searchCtrl = TextEditingController();
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (_router != router) {
      _router?.routerDelegate.removeListener(_onRouteChanged);
      _router = router;
      _router!.routerDelegate.addListener(_onRouteChanged);
    }
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final path = _router!.routerDelegate.currentConfiguration.uri.path;
    if (path == '/products') {
      context.read<ProductsBloc>().add(const ProductsLoadRequested());
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    context.read<ProductsBloc>().add(ProductsLoadRequested(search: _searchCtrl.text.trim()));
  }

  Future<void> _confirmDelete(BuildContext context, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // Avoid Navigator "locked" assert: run after dialog route is fully popped.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.read<ProductsBloc>().add(ProductDeleteRequested(id));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/products/new'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Product'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () {
                  _searchCtrl.clear();
                  _search();
                }),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(
            child: BlocConsumer<ProductsBloc, ProductsState>(
              listener: (context, state) {
                if (state is ProductSaveSuccess) {
                  context.read<ProductsBloc>().add(
                        ProductsLoadRequested(search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim()),
                      );
                } else if (state is ProductsFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ProductsLoading) return const Center(child: CircularProgressIndicator());
                if (state is ProductsSaving) return const Center(child: CircularProgressIndicator());
                if (state is ProductsFailure) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(state.message),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () => context.read<ProductsBloc>().add(const ProductsLoadRequested()), child: const Text('Retry')),
                  ]));
                }
                if (state is ProductsLoaded) {
                  if (state.products.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: state.products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = state.products[i];
                      return ListTile(
                        leading: p.images.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(p.images.first, width: 48, height: 48, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)))
                            : const Icon(Icons.image_not_supported_outlined, size: 48),
                        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '₹${p.price.toStringAsFixed(0)}'
                          '${p.categoryName != null ? ' · ${p.categoryName}' : ''}'
                          ' · ${p.isActive ? 'Active' : 'Inactive'}',
                        ),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Switch(
                            value: p.isActive,
                            onChanged: (v) => context.read<ProductsBloc>().add(
                                  ProductSaveRequested(
                                    id: p.id,
                                    data: {'isActive': v},
                                  ),
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => context.go('/products/${p.id}/edit'),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                            onPressed: () => _confirmDelete(context, p.id, p.name),
                          ),
                        ]),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
