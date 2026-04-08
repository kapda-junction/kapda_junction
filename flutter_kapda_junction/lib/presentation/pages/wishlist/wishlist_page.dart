import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/wishlist/wishlist_bloc.dart';
import '../../../data/datasources/remote/wishlist_datasource.dart';
import '../../../data/models/product_model.dart';
import '../../../core/di/injection.dart';
import '../../widgets/product/product_card.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  late final _ds = sl<WishlistDataSource>();
  List<ProductModel> _allProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _ds.getProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _loading = false;
      });
      // Sync badge count with actual fetched products
      context.read<WishlistBloc>().add(
        WishlistIdsUpdated(products.map((p) => p.id).toSet()),
      );
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          BlocBuilder<WishlistBloc, WishlistState>(
            builder: (context, state) {
              if (state.ids.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Clear wishlist?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    context.read<WishlistBloc>().add(const WishlistCleared());
                  }
                },
                child: const Text('Clear all'),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : BlocBuilder<WishlistBloc, WishlistState>(
              builder: (context, wishState) {
                // Filter products to only those still in wishlist
                final products = _allProducts
                    .where((p) => wishState.ids.contains(p.id))
                    .toList();

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_border, size: 72, color: cs.onSurfaceVariant),
                        const SizedBox(height: 14),
                        Text('No saved items yet', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text('Tap ♥ on any product to save it here',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                final width = MediaQuery.sizeOf(context).width;
                final cols = width >= 600 ? 3 : 2;
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: width >= 600 ? 0.70 : 0.68,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) => ProductCard(product: products[i]),
                );
              },
            ),
    );
  }
}
