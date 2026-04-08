import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../domain/entities/banner.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../bloc/home/home_bloc.dart';
import '../../widgets/product/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeBloc _bloc;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  String? _activeCategoryId;

  @override
  void initState() {
    super.initState();
    _bloc = sl<HomeBloc>()..add(HomeLoadRequested());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bloc.close();
    super.dispose();
  }

  List<_CategorySection> _buildSections(
    List<Category> categories,
    List<Product> products,
  ) {
    final sections = <_CategorySection>[];
    for (final category in categories) {
      final categoryIds = <String>{
        category.id,
        ...category.children.map((child) => child.id),
      };
      final items = products
          .where(
            (product) =>
                product.categoryId != null &&
                categoryIds.contains(product.categoryId),
          )
          .toList();
      if (items.isNotEmpty) {
        sections.add(_CategorySection(category: category, products: items));
      }
    }
    return sections;
  }

  void _jumpToCategory(String categoryId) {
    setState(() => _activeCategoryId = categoryId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _sectionKeys[categoryId]?.currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        alignment: 0.04,
      );
    });
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
        childAspectRatio: 0.88,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      );
    }
    if (width >= 800) {
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.84,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      );
    }
    if (width >= 600 || isLandscape) {
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.80,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      );
    }
    // Phone 2-column: image AspectRatio(0.82) + ~40dp info
    return const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.68,
      crossAxisSpacing: 12,
      mainAxisSpacing: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerHighest,
        appBar: AppBar(
          title: const _LogoTitle(),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => context.go('/search'),
            ),
          ],
        ),
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading || state is HomeInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is HomeFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _bloc.add(
                          const HomeLoadRequested(forceRefresh: true),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is! HomeLoaded) {
              return const SizedBox.shrink();
            }

            final sections = _buildSections(
              state.categories,
              state.allProducts,
            );
            final productGridDelegate = _gridDelegate(context);
            final spotlightProducts = state.featuredProducts.isNotEmpty
                ? state.featuredProducts.take(4).toList()
                : state.allProducts.take(4).toList();

            return RefreshIndicator(
              onRefresh: () async =>
                  _bloc.add(const HomeLoadRequested(forceRefresh: true)),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.banners.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: CarouselSlider(
                            options: CarouselOptions(
                              height: 230,
                              autoPlay: true,
                              viewportFraction: 1,
                              autoPlayInterval: const Duration(seconds: 4),
                            ),
                            items: state.banners
                                .map((banner) => _BannerSlide(banner: banner))
                                .toList(),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                      child: _LabelPill(label: 'Categories'),
                    ),
                    if (sections.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: sections.map((section) {
                            final isSelected =
                                _activeCategoryId == section.category.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: FilterChip(
                                selected: isSelected,
                                onSelected: (_) =>
                                    _jumpToCategory(section.category.id),
                                avatar: Icon(
                                  Icons.grid_view_rounded,
                                  size: 18,
                                  color: isSelected
                                      ? AppColors.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                label: Text(section.category.name),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (spotlightProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                        child: _LabelPill(label: 'Featured'),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        gridDelegate: productGridDelegate,
                        itemCount: spotlightProducts.length,
                        itemBuilder: (context, index) =>
                            ProductCard(product: spotlightProducts[index]),
                      ),
                    ],
                    for (final section in sections) ...[
                      Builder(
                        builder: (context) {
                          final key = _sectionKeys.putIfAbsent(
                            section.category.id,
                            GlobalKey.new,
                          );
                          return Container(
                            key: key,
                            margin: const EdgeInsets.fromLTRB(10, 12, 10, 0),
                            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: colorScheme.outline.withAlpha(28),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionHeading(
                                  label: 'Category',
                                  title: section.category.name,
                                  subtitle:
                                      '${section.products.length} products available',
                                ),
                                const SizedBox(height: 14),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: productGridDelegate,
                                  itemCount: section.products.length,
                                  itemBuilder: (context, index) => ProductCard(
                                    product: section.products[index],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    if (sections.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 58,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Products will appear here once categories are mapped.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String label;
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.label,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha(20),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _LabelPill extends StatelessWidget {
  final String label;
  const _LabelPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CategorySection {
  final Category category;
  final List<Product> products;

  const _CategorySection({required this.category, required this.products});
}

class _LogoTitle extends StatelessWidget {
  const _LogoTitle();

  static List<Shadow> _outline(Color c) => [
        Shadow(color: c, blurRadius: 0, offset: const Offset(-2, -2)),
        Shadow(color: c, blurRadius: 0, offset: const Offset(2, -2)),
        Shadow(color: c, blurRadius: 0, offset: const Offset(-2, 2)),
        Shadow(color: c, blurRadius: 0, offset: const Offset(2, 2)),
        Shadow(color: c, blurRadius: 0, offset: const Offset(0, -2)),
        Shadow(color: c, blurRadius: 0, offset: const Offset(0, 2)),
        Shadow(color: c, blurRadius: 0, offset: const Offset(-2, 0)),
        Shadow(color: c, blurRadius: 0, offset: const Offset(2, 0)),
        Shadow(color: c.withAlpha(100), blurRadius: 6, offset: const Offset(0, 3)),
      ];

  static const _navy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // "Kapda Junction" on one line
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Kapda',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFFBBF24),
                  shadows: _outline(_navy),
                ),
              ),
              TextSpan(
                text: ' Junction',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF7DD3FC),
                  shadows: _outline(_navy),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final AppBanner banner;

  const _BannerSlide({required this.banner});

  // Stagger (yOffset, rotationRad) per product count
  static const _stagger2 = [(-4.0, -0.02), (-10.0, 0.02)];
  static const _stagger3 = [(-4.0, -0.025), (-12.0, 0.028), (-2.0, -0.018)];
  static const _stagger4 = [(-4.0, -0.03), (-14.0, 0.025), (-2.0, -0.02), (-12.0, 0.035)];

  @override
  Widget build(BuildContext context) {
    final products = banner.products.take(4).toList();
    final count = products.length;

    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: banner.image,
          width: double.infinity,
          height: 260,
          fit: BoxFit.cover,
          errorWidget: (c, e, s) => Container(color: AppColors.border),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.48, 1.0],
              colors: [
                Colors.transparent,
                Colors.black.withAlpha(70),
                Colors.black.withAlpha(210),
              ],
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: count == 1
                // Single product: right-aligned, constrained width
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 130,
                        child: _ProductMiniCard(product: products[0]),
                      ),
                    ],
                  )
                // 2–4 products: staggered row
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(count, (i) {
                      final stagger = count == 2
                          ? _stagger2
                          : count == 3
                              ? _stagger3
                              : _stagger4;
                      final (yOff, rot) =
                          i < stagger.length ? stagger[i] : (0.0, 0.0);
                      return Expanded(
                        child: Transform.translate(
                          offset: Offset(0, yOff),
                          child: Transform.rotate(
                            angle: rot,
                            child: _ProductMiniCard(product: products[i]),
                          ),
                        ),
                      );
                    }),
                  ),
          ),
      ],
    );
  }
}

class _ProductMiniCard extends StatelessWidget {
  final BannerProduct product;

  const _ProductMiniCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(90),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 0.85,
                child: product.image != null
                    ? CachedNetworkImage(
                        imageUrl: product.image!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (c, e, s) => _imgPlaceholder(),
                      )
                    : _imgPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: AppTypography.labelMedium.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    PriceFormatter.format(product.price),
                    style: AppTypography.labelMedium.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    color: AppColors.border,
    child: const Center(
      child: Icon(Icons.checkroom, size: 28, color: AppColors.textHint),
    ),
  );
}
