import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../data/datasources/remote/activity_datasource.dart';
import '../../bloc/products/products_bloc.dart';
import '../../widgets/product/product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final ProductsBloc _bloc;
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  List<String> _recentSearches = [];
  List<String> _suggestions = [];
  bool _showDropdown = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _bloc = sl<ProductsBloc>();
    _loadRecent();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showDropdown = true);
      } else {
        // Delay so tap on suggestion registers before dropdown hides
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showDropdown = false);
        });
      }
    });

    _searchCtrl.addListener(() {
      _debounce?.cancel();
      final q = _searchCtrl.text.trim();
      if (q.length < 2) {
        setState(() => _suggestions = []);
        return;
      }
      _debounce = Timer(const Duration(milliseconds: 350), () => _fetchSuggestions(q));
    });
  }

  Future<void> _loadRecent() async {
    final searches = await sl<ActivityDataSource>().getRecentSearches();
    if (mounted) setState(() => _recentSearches = searches);
  }

  Future<void> _fetchSuggestions(String q) async {
    final results = await sl<ActivityDataSource>().getSuggestions(q);
    if (mounted) setState(() => _suggestions = results);
  }

  void _submit(String q) {
    q = q.trim();
    if (q.isEmpty) return;
    _focusNode.unfocus();
    setState(() => _showDropdown = false);
    _searchCtrl.text = q;
    _bloc.add(ProductsSearchRequested(query: q));
    sl<ActivityDataSource>().trackSearch(q);
    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _bloc.close();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) {
      return const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, childAspectRatio: 0.76, crossAxisSpacing: 12, mainAxisSpacing: 12);
    }
    if (width >= 800) {
      return const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12);
    }
    if (width >= 600) {
      return const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, childAspectRatio: 0.66, crossAxisSpacing: 10, mainAxisSpacing: 10);
    }
    return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.56, crossAxisSpacing: 10, mainAxisSpacing: 10);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: cs.surfaceContainerHighest,
        appBar: AppBar(title: const Text('Search')),
        body: Column(
          children: [
            // ── Search bar ────────────────────────────────────────────
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                onSubmitted: _submit,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search products, categories...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _suggestions = []);
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_forward, color: AppColors.accent),
                          onPressed: () => _submit(_searchCtrl.text),
                        ),
                  filled: true,
                  fillColor: Colors.white.withAlpha(26),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ── Dropdown: suggestions or recent searches ──────────────
            if (_showDropdown) _buildDropdown(cs),

            // ── Results ───────────────────────────────────────────────
            if (!_showDropdown)
              Expanded(
                child: BlocBuilder<ProductsBloc, ProductsState>(
                  builder: (context, state) {
                    if (state is ProductsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ProductsFailure) {
                      return Center(child: Text(state.message));
                    }
                    if (state is ProductsLoaded) {
                      if (state.products.isEmpty) {
                        return Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.search_off, size: 56, color: cs.onSurfaceVariant),
                            const SizedBox(height: 10),
                            const Text('No products found'),
                          ]),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: _gridDelegate(context),
                        itemCount: state.products.length,
                        itemBuilder: (_, i) => ProductCard(product: state.products[i]),
                      );
                    }
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.search, size: 64, color: cs.onSurfaceVariant),
                        const SizedBox(height: 10),
                        Text('Search for products',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(ColorScheme cs) {
    final query = _searchCtrl.text.trim();
    final hasQuery = query.length >= 2;
    final items = hasQuery ? _suggestions : _recentSearches;
    final label = hasQuery ? 'Suggestions' : 'Recent searches';
    final icon = hasQuery ? Icons.search : Icons.history;

    if (items.isEmpty && !hasQuery) {
      return Container(
        color: cs.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(Icons.history, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Text('No recent searches', style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: cs.onSurfaceVariant)),
        ]),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      color: cs.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(label,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 0.5)),
          ),
          ...items.map((item) => InkWell(
                onTap: () => _submit(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(children: [
                    Icon(icon, size: 17, color: cs.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Icon(Icons.north_west, size: 14, color: cs.onSurfaceVariant),
                  ]),
                ),
              )),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
