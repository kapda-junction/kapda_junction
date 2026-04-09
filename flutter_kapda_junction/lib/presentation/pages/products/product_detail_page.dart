import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/error/app_error_handler.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../data/datasources/remote/activity_datasource.dart';
import '../../../data/datasources/remote/home_remote_datasource.dart';
import '../../../data/datasources/remote/review_remote_datasource.dart';
import '../../../domain/entities/product.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/products/products_bloc.dart';
import '../../bloc/wishlist/wishlist_bloc.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  final Product? initialProduct;
  final bool openedFromPush;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.initialProduct,
    this.openedFromPush = false,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final ProductsBloc _bloc;
  late final Future<Map<String, dynamic>> _reviewsFuture;
  final _pageCtrl = PageController();
  String? _selectedColor;
  String? _selectedSize;
  int _imgIndex = 0;
  String? _whatsappNumber;

  @override
  void initState() {
    super.initState();
    _reviewsFuture =
        sl<ReviewRemoteDataSource>().getProductReviews(widget.productId);
    _bloc = sl<ProductsBloc>()..add(ProductDetailRequested(widget.productId));
    final p = widget.initialProduct;
    if (p != null) {
      sl<ActivityDataSource>().trackView(
        p.id, p.name, p.images.isNotEmpty ? p.images.first : null,
      );
    }
    _loadWhatsAppNumber();
  }

  Future<void> _loadWhatsAppNumber() async {
    try {
      final m = await sl<HomeRemoteDataSource>().getSettings();
      final number = (m['whatsappInquiryNumber'] ?? '').toString();
      if (mounted && number.isNotEmpty) setState(() => _whatsappNumber = number);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bloc.close();
    super.dispose();
  }

  bool _addToCart(BuildContext context, Product product) {
    if (product.variants.isNotEmpty &&
        (_selectedColor == null || _selectedSize == null)) {
      AppErrorHandler.show('Please select color and size', title: 'Select Options');
      return false;
    }
    context.read<CartBloc>().add(CartItemAdded(
      product: product,
      color: _selectedColor,
      size: _selectedSize,
    ));
    AppNotification.showSuccess(context, 'Added to cart');
    return true;
  }

  Future<void> _openWhatsApp(Product product) async {
    final shareUrl = ApiConstants.shareProductUrl(product.id);
    final msg = Uri.encodeComponent(
      'Hi! I\'m interested in buying *${product.name}* '
      '(${PriceFormatter.format(product.price)}). Is it available?\n\n'
      '🔗 $shareUrl',
    );
    final number = (_whatsappNumber?.isNotEmpty == true) ? _whatsappNumber! : '919770525851';
    final uri = Uri.parse('https://wa.me/$number?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareProduct(Product product) async {
    final shareUrl = ApiConstants.shareProductUrl(product.id);
    final caption = '*${product.name}*\n'
        '${PriceFormatter.format(product.price)}\n'
        'Shop at Kapda Junction 🛍️\n\n'
        '$shareUrl';
    try {
      final imageUrl = product.images.isNotEmpty ? product.images.first : null;
      if (imageUrl != null) {
        final response = await Dio().get<List<int>>(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/share_${product.id}.jpg');
        await file.writeAsBytes(response.data!);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/jpeg')],
          text: caption,
        );
        return;
      }
    } catch (_) {}
    await Share.share(caption);
  }

  static Color _swatchOf(String name) {
    const m = <String, Color>{
      'black': Color(0xFF1C1C1C),
      'white': Color(0xFFF5F5F5),
      'red': Color(0xFFE53935),
      'blue': Color(0xFF1E88E5),
      'navy': Color(0xFF1A237E),
      'dark blue': Color(0xFF0D47A1),
      'sky blue': Color(0xFF4FC3F7),
      'royal blue': Color(0xFF1565C0),
      'light blue': Color(0xFF81D4FA),
      'green': Color(0xFF43A047),
      'dark green': Color(0xFF1B5E20),
      'bottle green': Color(0xFF004D40),
      'light green': Color(0xFFA5D6A7),
      'yellow': Color(0xFFFDD835),
      'mustard': Color(0xFFFFB300),
      'orange': Color(0xFFE65100),
      'pink': Color(0xFFE91E63),
      'hot pink': Color(0xFFFF4081),
      'light pink': Color(0xFFF48FB1),
      'peach': Color(0xFFFFCC80),
      'purple': Color(0xFF7B1FA2),
      'lavender': Color(0xFFCE93D8),
      'grey': Color(0xFF757575),
      'gray': Color(0xFF757575),
      'light grey': Color(0xFFBDBDBD),
      'dark grey': Color(0xFF424242),
      'charcoal': Color(0xFF37474F),
      'brown': Color(0xFF6D4C41),
      'chocolate': Color(0xFF4E342E),
      'maroon': Color(0xFF880E4F),
      'wine': Color(0xFF6A1B2A),
      'teal': Color(0xFF00897B),
      'cyan': Color(0xFF00ACC1),
      'coral': Color(0xFFFF7043),
      'cream': Color(0xFFFFF9C4),
      'beige': Color(0xFFF5DEB3),
      'off white': Color(0xFFF5F0E8),
      'olive': Color(0xFF827717),
      'gold': Color(0xFFFFB300),
      'silver': Color(0xFFB0BEC5),
      'indigo': Color(0xFF3949AB),
      'khaki': Color(0xFFC8A96E),
      'rust': Color(0xFFBF360C),
      'mint': Color(0xFF80CBC4),
    };
    return m[name.toLowerCase().trim()] ?? const Color(0xFF9E9E9E);
  }

  static bool _isDarkSwatch(Color c) => c.computeLuminance() < 0.35;

  void _handleBackPressed(BuildContext context) {
    if (widget.openedFromPush) {
      context.go('/');
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenH = MediaQuery.sizeOf(context).height;
    final imageH = (screenH * 0.52).clamp(320.0, 500.0);
    final top = MediaQuery.of(context).padding.top;

    return BlocProvider.value(
      value: _bloc,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
        child: Scaffold(
          backgroundColor: cs.surface,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _FloatBtn(
                  icon: Icons.arrow_back,
                  onTap: () => _handleBackPressed(context)),
            ),
            actions: [
              BlocBuilder<WishlistBloc, WishlistState>(
                builder: (context, ws) {
                  final product = context.select<ProductsBloc, Product?>(
                    (b) => b.state is ProductDetailLoaded
                        ? (b.state as ProductDetailLoaded).product
                        : widget.initialProduct,
                  );
                  if (product == null) return const SizedBox.shrink();
                  final fav = ws.contains(product.id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _FloatBtn(
                      icon: fav ? Icons.favorite : Icons.favorite_border,
                      iconColor: fav ? Colors.red : null,
                      onTap: () => context
                          .read<WishlistBloc>()
                          .add(WishlistToggleRequested(product.id)),
                    ),
                  );
                },
              ),
              Builder(
                builder: (innerContext) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _FloatBtn(
                    icon: Icons.ios_share_rounded,
                    onTap: () {
                      final state = innerContext.read<ProductsBloc>().state;
                      final p = state is ProductDetailLoaded
                          ? state.product
                          : widget.initialProduct;
                      if (p != null) _shareProduct(p);
                    },
                  ),
                ),
              ),
            ],
          ),
          body: BlocBuilder<ProductsBloc, ProductsState>(
            builder: (context, state) {
              final product = state is ProductDetailLoaded
                  ? state.product
                  : widget.initialProduct;

              if ((state is ProductDetailLoading ||
                      state is ProductsLoading) &&
                  product == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ProductsFailure && product == null) {
                return Center(child: Text(state.message));
              }
              if (product == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final colors = product.availableColors;
              final sizes = product.allSizesForColor(_selectedColor);
              final imgs = product.imagesForColor(_selectedColor);

              return CustomScrollView(
                slivers: [
                  // ── Hero image ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: imageH + top,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image / PageView
                          imgs.isEmpty
                              ? Container(
                                  color: cs.surfaceContainerHighest,
                                  child: Icon(Icons.checkroom,
                                      size: 80,
                                      color: cs.onSurfaceVariant),
                                )
                              : PageView.builder(
                                  controller: _pageCtrl,
                                  itemCount: imgs.length,
                                  onPageChanged: (i) =>
                                      setState(() => _imgIndex = i),
                                  itemBuilder: (_, i) => CachedNetworkImage(
                                    imageUrl: imgs[i],
                                    fit: BoxFit.cover,
                                    errorWidget: (c, e, s) => Container(
                                        color: cs.surfaceContainerHighest),
                                  ),
                                ),

                          // Bottom gradient to blend with content card
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 120,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    cs.surface.withAlpha(210),
                                    cs.surface,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Out-of-stock overlay
                          if (product.soldOut)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withAlpha(80),
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.red.withAlpha(80),
                                          blurRadius: 20)
                                    ],
                                  ),
                                  child: Text('OUT OF STOCK',
                                      style: tt.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2)),
                                ),
                              ),
                            ),

                          // Image counter pill (top-right, below appbar)
                          if (imgs.length > 1)
                            Positioned(
                              top: top + 56,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(130),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_imgIndex + 1} / ${imgs.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                          // Dot indicators
                          if (imgs.length > 1)
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  imgs.length > 8 ? 8 : imgs.length,
                                  (i) => AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    width: i == _imgIndex ? 20 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: i == _imgIndex
                                          ? AppColors.accent
                                          : Colors.white.withAlpha(140),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Content ───────────────────────────────────────────
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(
                      color: cs.surface,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category chip + WhatsApp
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (product.categoryName != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withAlpha(22),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      product.categoryName!.toUpperCase(),
                                      style: tt.labelSmall?.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                // WhatsApp enquiry button
                                GestureDetector(
                                  onTap: () => _openWhatsApp(product),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF25D366)
                                          .withAlpha(18),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: const Color(0xFF25D366)
                                              .withAlpha(60),
                                          width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/icons/whatsapp.png',
                                          width: 18,
                                          height: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Enquire',
                                          style: tt.labelSmall?.copyWith(
                                            color: const Color(0xFF128C7E),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Product name
                            Text(
                              product.name,
                              style: tt.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Price row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  PriceFormatter.format(product.price),
                                  style: tt.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (product.hasDiscount) ...[
                                  const SizedBox(width: 10),
                                  Text(
                                    PriceFormatter.format(
                                        product.compareAtPrice!),
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${product.discountPercent}% OFF',
                                      style: tt.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // Savings amount
                            if (product.hasDiscount) ...[
                              const SizedBox(height: 4),
                              Text(
                                'You save ${PriceFormatter.format(product.compareAtPrice! - product.price)}',
                                style: tt.labelMedium?.copyWith(
                                  color: const Color(0xFF22C55E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],

                            // Description
                            if (product.description?.trim().isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 12),
                              Text(
                                product.description!,
                                style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant, height: 1.6),
                              ),
                            ],

                            FutureBuilder<Map<String, dynamic>>(
                              future: _reviewsFuture,
                              builder: (ctx, snap) {
                                if (snap.connectionState ==
                                        ConnectionState.waiting ||
                                    snap.hasError ||
                                    !snap.hasData) {
                                  return const SizedBox.shrink();
                                }
                                final data = snap.data!;
                                final count =
                                    (data['reviewCount'] as num?)?.toInt() ?? 0;
                                final avg =
                                    (data['averageRating'] as num?)?.toDouble() ??
                                        0;
                                final raw =
                                    (data['reviews'] as List?)?.cast<dynamic>() ??
                                        [];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20),
                                    Text(
                                      'Customer reviews',
                                      style: tt.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (count == 0)
                                      Text(
                                        'No approved reviews yet. Buy and review after delivery.',
                                        style: tt.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      )
                                    else ...[
                                      Text(
                                        '${avg.toStringAsFixed(1)} ★ · $count review${count == 1 ? '' : 's'}',
                                        style: tt.labelLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (count > 3) ...[
                                        const SizedBox(height: 4),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton(
                                            onPressed: () => context.push(
                                              '/product/${widget.productId}/reviews',
                                            ),
                                            child: Text(
                                              'View all $count reviews',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: cs.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      ...raw.take(3).map((r) {
                                        final m = r as Map<String, dynamic>;
                                        final title =
                                            (m['title'] ?? '').toString();
                                        final body =
                                            (m['body'] ?? '').toString();
                                        final name =
                                            (m['userName'] ?? 'Customer')
                                                .toString();
                                        final stars =
                                            (m['rating'] as num?)?.toInt() ?? 0;
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          child: Material(
                                            color: cs.surfaceContainerHighest
                                                .withAlpha(50),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '★' * stars,
                                                        style: tt.labelMedium
                                                            ?.copyWith(
                                                          color: cs.secondary,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          name,
                                                          style: tt.labelSmall
                                                              ?.copyWith(
                                                            color: cs
                                                                .onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (title.isNotEmpty)
                                                    Text(
                                                      title,
                                                      style: tt.bodyMedium
                                                          ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  if (body.isNotEmpty)
                                                    Text(
                                                      body,
                                                      style: tt.bodySmall,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                );
                              },
                            ),

                            // ── Trust badges ──────────────────────────────
                            const SizedBox(height: 16),
                            _TrustBadges(),
                            const SizedBox(height: 16),

                            // Divider
                            Divider(
                                color: cs.outlineVariant.withAlpha(80),
                                height: 1),
                            const SizedBox(height: 16),

                            // ── Colors ────────────────────────────────────
                            if (colors.isNotEmpty) ...[
                              _SectionHeader(
                                label: 'Color',
                                value: _selectedColor,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 14,
                                runSpacing: 14,
                                children: colors.map((c) {
                                  final sel = _selectedColor == c;
                                  final swatch = _swatchOf(c);
                                  final isDark = _isDarkSwatch(swatch);
                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedColor = c;
                                      _selectedSize = null;
                                      _imgIndex = 0;
                                      if (_pageCtrl.hasClients) {
                                        _pageCtrl.jumpToPage(0);
                                      }
                                    }),
                                    child: Column(
                                      children: [
                                        // Double-ring effect: outer accent ring → white gap → swatch
                                        AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 200),
                                          width: sel ? 52 : 46,
                                          height: sel ? 52 : 46,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: sel
                                                ? Border.all(
                                                    color: AppColors.accent,
                                                    width: 2.5)
                                                : null,
                                            boxShadow: sel
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.accent
                                                          .withAlpha(60),
                                                      blurRadius: 10,
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          padding: sel
                                              ? const EdgeInsets.all(3)
                                              : EdgeInsets.zero,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: swatch,
                                              border: !sel
                                                  ? Border.all(
                                                      color: Colors.black
                                                          .withAlpha(18),
                                                      width: 1)
                                                  : null,
                                            ),
                                            child: sel
                                                ? Icon(Icons.check,
                                                    size: 16,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black87)
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          c,
                                          style: tt.labelSmall?.copyWith(
                                            color: sel
                                                ? AppColors.accent
                                                : cs.onSurfaceVariant,
                                            fontWeight: sel
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // ── Sizes ──────────────────────────────────────
                            if (sizes.isNotEmpty) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _SectionHeader(
                                      label: 'Size',
                                      value: _selectedSize,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.push('/size-guide'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: const Text('Size guide →', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: sizes.map((s) {
                                  final sel = _selectedSize == s;
                                  final avail = product.isVariantAvailable(
                                      _selectedColor ?? '', s);
                                  return GestureDetector(
                                    onTap: avail
                                        ? () => setState(
                                            () => _selectedSize = s)
                                        : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 180),
                                      width: 58,
                                      height: 50,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? AppColors.primary
                                            : avail
                                                ? cs.surface
                                                : cs.surfaceContainerHighest
                                                    .withAlpha(120),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: sel
                                              ? AppColors.accent
                                              : avail
                                                  ? cs.outlineVariant
                                                  : cs.outline.withAlpha(50),
                                          width: sel ? 2 : 1,
                                        ),
                                        boxShadow: sel
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.accent
                                                      .withAlpha(50),
                                                  blurRadius: 8,
                                                  offset:
                                                      const Offset(0, 2),
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Text(
                                            s,
                                            style:
                                                tt.bodySmall?.copyWith(
                                              color: sel
                                                  ? Colors.white
                                                  : avail
                                                      ? cs.onSurface
                                                      : cs.onSurface
                                                          .withAlpha(60),
                                              fontWeight: sel
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (!avail)
                                            Positioned.fill(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                                child: CustomPaint(
                                                  painter:
                                                      _StrikethroughPainter(
                                                          cs.outline
                                                              .withAlpha(
                                                                  80)),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],

                            SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom + 110,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Bottom bar ────────────────────────────────────────────────
          bottomNavigationBar: BlocBuilder<ProductsBloc, ProductsState>(
            builder: (context, state) {
              final product = state is ProductDetailLoaded
                  ? state.product
                  : widget.initialProduct;
              if (product == null) return const SizedBox.shrink();

              return Container(
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Add to Cart
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.shopping_bag_outlined,
                            size: 18),
                        label: const Text('Add to Cart'),
                        onPressed: product.soldOut
                            ? null
                            : () => _addToCart(context, product),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(
                              color: AppColors.accent.withAlpha(180),
                              width: 1.5),
                          foregroundColor: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Buy Now — gradient button
                    Expanded(
                      flex: 2,
                      child: product.soldOut
                          ? _GradientButton(
                              label: 'Buy Now',
                              onTap: null,
                            )
                          : _GradientButton(
                              label: 'Buy Now',
                              onTap: () {
                                if (_addToCart(context, product)) {
                                  context.push('/checkout');
                                }
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Gradient Buy Now button ───────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: onTap == null
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFE97316)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: onTap == null ? Colors.grey.shade300 : null,
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withAlpha(80),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: onTap == null ? Colors.grey.shade500 : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ── Trust badges row ─────────────────────────────────────────────────────────
class _TrustBadges extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final badges = [
      (Icons.local_shipping_outlined, 'Free Delivery'),
      (Icons.verified_outlined, '100% Genuine'),
      (Icons.replay_outlined, 'Easy Returns'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withAlpha(60)),
      ),
      child: Row(
        children: badges.map((b) {
          final isLast = b == badges.last;
          return Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Icon(b.$1,
                          size: 22,
                          color: AppColors.accent),
                      const SizedBox(height: 4),
                      Text(
                        b.$2,
                        textAlign: TextAlign.center,
                        style: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                      width: 1,
                      height: 32,
                      color: cs.outlineVariant.withAlpha(80)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Section header with selected value label ─────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final String? value;
  const _SectionHeader({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(label,
            style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w800, letterSpacing: 0.2)),
        if (value != null) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(value!,
                style: tt.labelSmall?.copyWith(
                    color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }
}

// ── Floating button on image ──────────────────────────────────────────────────
class _FloatBtn extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  const _FloatBtn({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.surface.withAlpha(220),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Icon(icon, color: iconColor ?? cs.onSurface, size: 20),
        ),
      ),
    );
  }
}

// ── Diagonal strikethrough for out-of-stock sizes ────────────────────────────
class _StrikethroughPainter extends CustomPainter {
  final Color color;
  const _StrikethroughPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(4, size.height - 4),
      Offset(size.width - 4, 4),
      Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StrikethroughPainter old) => old.color != color;
}
