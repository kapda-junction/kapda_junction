import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../bloc/wishlist/wishlist_bloc.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _imgIndex = 0;
  final _pageCtrl = PageController();
  Timer? _imgTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScrollIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id ||
        oldWidget.product.images.length != widget.product.images.length) {
      _imgTimer?.cancel();
      _imgIndex = 0;
      if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(0);
      _startAutoScrollIfNeeded();
    }
  }

  @override
  void dispose() {
    _imgTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _startAutoScrollIfNeeded() {
    if (widget.product.images.length <= 1) return;
    _imgTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageCtrl.hasClients) return;
      final next = (_imgIndex + 1) % widget.product.images.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _shareProduct() {
    final p = widget.product;
    final shareUrl = ApiConstants.shareProductUrl(p.id);
    Share.share(
      '*${p.name}*\n'
      '${PriceFormatter.format(p.price)}\n'
      'Shop at Kapda Junction 🛍️\n\n'
      '$shareUrl',
      subject: p.name,
    );
  }

@override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imgs = product.images;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/product/${product.id}', extra: product),
              child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(28),
                    blurRadius: 18,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image area — portrait ratio for fashion ──────────
                  AspectRatio(
                    aspectRatio: 0.82,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imgs.isEmpty
                            ? _placeholder()
                            : PageView.builder(
                                controller: _pageCtrl,
                                onPageChanged: (i) => setState(() => _imgIndex = i),
                                itemCount: imgs.length,
                                itemBuilder: (_, i) => CachedNetworkImage(
                                  imageUrl: imgs[i],
                                  fit: BoxFit.cover,
                                  errorWidget: (c, e, s) => _placeholder(),
                                ),
                              ),
                        // Dot indicators
                        if (imgs.length > 1)
                          Positioned(
                            bottom: 5,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                imgs.length > 5 ? 5 : imgs.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  width: i == _imgIndex ? 10 : 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: i == _imgIndex ? Colors.white : Colors.white54,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Hero / discount badge
                        Positioned(
                          top: 8,
                          left: 8,
                          child: product.hasDiscount
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53935),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${product.discountPercent}% OFF',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              : (product.heroTag?.isNotEmpty == true)
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        product.heroTag!,
                                        style: AppTypography.labelMedium.copyWith(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                        ),
                        // Wishlist button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: BlocBuilder<WishlistBloc, WishlistState>(
                            builder: (context, wishState) {
                              final isFav = wishState.contains(product.id);
                              return InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => context.read<WishlistBloc>()
                                    .add(WishlistToggleRequested(product.id)),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: cs.surface.withAlpha(228),
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: cs.outline.withAlpha(45)),
                                  ),
                                  child: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    size: 16,
                                    color: isFav ? Colors.red : cs.onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Share button
                        Positioned(
                          top: 46,
                          right: 8,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: _shareProduct,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: cs.surface.withAlpha(228),
                                shape: BoxShape.circle,
                                border: Border.all(color: cs.outline.withAlpha(45)),
                              ),
                              child: Icon(
                                Icons.share_outlined,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        // Sold out overlay
                        if (product.soldOut)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withAlpha(102),
                              alignment: Alignment.center,
                              child: Text('SOLD OUT',
                                  style: tt.labelMedium?.copyWith(
                                      color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // ── Info: name | price | chat — all one compact row ─
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              PriceFormatter.format(product.price),
                              style: AppTypography.price.copyWith(
                                fontSize: 13,
                                color: AppColors.accent,
                              ),
                            ),
                            if (product.hasDiscount)
                              Text(
                                PriceFormatter.format(product.compareAtPrice!),
                                style: AppTypography.priceStrikethrough
                                    .copyWith(fontSize: 9, color: cs.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          );
        },
      );
  }

  Widget _placeholder() => Container(
        color: AppColors.border,
        child: const Center(child: Icon(Icons.checkroom, size: 32, color: AppColors.textHint)),
      );
}
