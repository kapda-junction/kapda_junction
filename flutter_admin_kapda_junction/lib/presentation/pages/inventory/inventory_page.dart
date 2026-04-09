import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/di/injection.dart';
import '../../widgets/common/admin_drawer.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _api = sl<ApiClient>();
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  List<_InventoryProduct> _all = [];
  List<_InventoryProduct> _low = [];
  List<_InventoryProduct> _out = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final q = _searchCtrl.text.trim();
      final res = await _api.get(
        ApiConstants.inventory,
        params: q.isEmpty ? null : {'search': q},
      );
      final products = (res.data['products'] as List)
          .map((e) => _InventoryProduct.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _all = products;
        _low = products.where((p) => p.lowStockVariants > 0 && p.totalStock > 0).toList();
        _out = products.where((p) => p.totalStock == 0).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('All', _all),
      ('Low Stock', _low),
      ('Out of Stock', _out),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Inventory', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search name, shop code, SKU…',
                    prefixIcon: const Icon(Icons.search, size: 22),
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(100)),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchCtrl.clear();
                              _load();
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: 'Search',
                          onPressed: _load,
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: (_) => _load(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              TabBar(
          controller: _tabs,
          labelColor: AppColors.accent,
          indicatorColor: AppColors.accent,
          tabs: tabs.map((t) => Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.$1),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${t.$2.length}', style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
          )).toList(),
              ),
            ],
          ),
        ),
      ),
      drawer: const AdminDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : TabBarView(
                  controller: _tabs,
                  children: tabs.map((t) => _ProductList(
                    products: t.$2,
                    onStockUpdated: _load,
                    api: _api,
                  )).toList(),
                ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<_InventoryProduct> products;
  final VoidCallback onStockUpdated;
  final ApiClient api;

  const _ProductList({
    required this.products,
    required this.onStockUpdated,
    required this.api,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Text('No products', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductCard(
        product: products[i],
        onStockUpdated: onStockUpdated,
        api: api,
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final _InventoryProduct product;
  final VoidCallback onStockUpdated;
  final ApiClient api;

  const _ProductCard({
    required this.product,
    required this.onStockUpdated,
    required this.api,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _expanded = false;

  Color _stockColor(int stock) {
    if (stock == 0) return const Color(0xFFDC2626);
    if (stock <= 5) return const Color(0xFFF59E0B);
    return const Color(0xFF059669);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Column(
        children: [
          // ── Header ──
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: p.image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: p.image,
                            width: 52, height: 52,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const _NoImg(),
                          )
                        : const _NoImg(),
                  ),
                  const SizedBox(width: 12),
                  // Name + stock summary
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (p.shopCode != null && p.shopCode!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withAlpha(22),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.shopCode!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(children: [
                          _StockBadge(label: 'Total: ${p.totalStock}', color: _stockColor(p.totalStock)),
                          if (p.outOfStockVariants > 0) ...[
                            const SizedBox(width: 6),
                            _StockBadge(label: '${p.outOfStockVariants} out', color: const Color(0xFFDC2626)),
                          ],
                          if (p.lowStockVariants > 0) ...[
                            const SizedBox(width: 6),
                            _StockBadge(label: '${p.lowStockVariants} low', color: const Color(0xFFF59E0B)),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey),
                ],
              ),
            ),
          ),

          // ── Variants ──
          if (_expanded) ...[
            const Divider(height: 1),
            ...p.variants.map((v) => _VariantRow(
              productId: p.id,
              variant: v,
              stockColor: _stockColor(v.stock),
              api: widget.api,
              onUpdated: widget.onStockUpdated,
            )),
          ],
        ],
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  final String productId;
  final _InventoryVariant variant;
  final Color stockColor;
  final ApiClient api;
  final VoidCallback onUpdated;

  const _VariantRow({
    required this.productId,
    required this.variant,
    required this.stockColor,
    required this.api,
    required this.onUpdated,
  });

  Future<void> _editStock(BuildContext context) async {
    final ctrl = TextEditingController(text: variant.stock.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Update Stock — ${variant.color} / ${variant.size}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (variant.sku != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('SKU: ${variant.sku}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Stock Quantity',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v >= 0) Navigator.pop(context, v);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await api.patch(
        ApiConstants.productStock(productId),
        data: {'variantId': variant.id, 'stock': result},
      );
      onUpdated();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock updated to $result'), backgroundColor: const Color(0xFF059669)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _editStock(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${variant.color}  ·  ${variant.size}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  if (variant.sku != null)
                    Text(variant.sku!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: stockColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: stockColor.withAlpha(80)),
              ),
              child: Text(
                variant.stock == 0 ? 'Out' : '${variant.stock}',
                style: TextStyle(color: stockColor, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_outlined, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StockBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _NoImg extends StatelessWidget {
  const _NoImg();
  @override
  Widget build(BuildContext context) => Container(
    width: 52, height: 52,
    color: const Color(0xFFE2E8F0),
    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 20),
  );
}

// ── Data models ──

class _InventoryProduct {
  final String id;
  final String name;
  final String? shopCode;
  final String image;
  final int totalStock;
  final int outOfStockVariants;
  final int lowStockVariants;
  final List<_InventoryVariant> variants;

  const _InventoryProduct({
    required this.id,
    required this.name,
    this.shopCode,
    required this.image,
    required this.totalStock,
    required this.outOfStockVariants,
    required this.lowStockVariants,
    required this.variants,
  });

  factory _InventoryProduct.fromJson(Map<String, dynamic> j) => _InventoryProduct(
    id: j['_id'] as String,
    name: j['name'] as String? ?? '',
    shopCode: j['shopCode'] as String?,
    image: ((j['images'] as List?)?.firstOrNull as String?) ?? '',
    totalStock: (j['totalStock'] as num?)?.toInt() ?? 0,
    outOfStockVariants: (j['outOfStockVariants'] as num?)?.toInt() ?? 0,
    lowStockVariants: (j['lowStockVariants'] as num?)?.toInt() ?? 0,
    variants: ((j['variants'] as List?) ?? [])
        .map((v) => _InventoryVariant.fromJson(v as Map<String, dynamic>))
        .toList(),
  );
}

class _InventoryVariant {
  final String id;
  final String color;
  final String size;
  final int stock;
  final String? sku;

  const _InventoryVariant({
    required this.id,
    required this.color,
    required this.size,
    required this.stock,
    this.sku,
  });

  factory _InventoryVariant.fromJson(Map<String, dynamic> j) => _InventoryVariant(
    id: j['_id'] as String,
    color: j['color'] as String? ?? '',
    size: j['size'] as String? ?? '',
    stock: (j['stock'] as num?)?.toInt() ?? 0,
    sku: j['sku'] as String?,
  );
}
