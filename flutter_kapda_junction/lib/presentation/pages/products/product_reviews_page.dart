import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../data/datasources/remote/review_remote_datasource.dart';

/// Full list of approved reviews for a product (keeps product detail shorter).
class ProductReviewsPage extends StatefulWidget {
  final String productId;

  const ProductReviewsPage({super.key, required this.productId});

  @override
  State<ProductReviewsPage> createState() => _ProductReviewsPageState();
}

class _ProductReviewsPageState extends State<ProductReviewsPage> {
  late final Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future =
        sl<ReviewRemoteDataSource>().getProductReviews(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All reviews',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Text(
                'Could not load reviews',
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
            );
          }
          final data = snap.data!;
          final count =
              (data['reviewCount'] as num?)?.toInt() ?? 0;
          final avg =
              (data['averageRating'] as num?)?.toDouble() ?? 0;
          final raw =
              (data['reviews'] as List?)?.cast<dynamic>() ?? [];

          if (count == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No approved reviews yet.',
                  textAlign: TextAlign.center,
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                '${avg.toStringAsFixed(1)} ★ · $count review${count == 1 ? '' : 's'}',
                style:
                    tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ...raw.map((r) {
                final m = r as Map<String, dynamic>;
                final title = (m['title'] ?? '').toString();
                final body = (m['body'] ?? '').toString();
                final name =
                    (m['userName'] ?? 'Customer').toString();
                final stars = (m['rating'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: cs.surfaceContainerHighest.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '★' * stars,
                                style: tt.labelMedium?.copyWith(
                                  color: cs.secondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (title.isNotEmpty)
                            Text(
                              title,
                              style: tt.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          if (body.isNotEmpty) Text(body, style: tt.bodySmall),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
