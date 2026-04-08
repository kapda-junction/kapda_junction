import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../../data/datasources/remote/reviews_admin_datasource.dart';
import '../../widgets/common/admin_drawer.dart';

class ReviewsModerationPage extends StatefulWidget {
  const ReviewsModerationPage({super.key});

  @override
  State<ReviewsModerationPage> createState() => _ReviewsModerationPageState();
}

class _ReviewsModerationPageState extends State<ReviewsModerationPage> {
  final _ds = sl<ReviewsAdminDataSource>();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _filter; // pending | approved | rejected | null=all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _ds.list(status: _filter);
      if (mounted) {
        setState(() {
          _list = rows;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await _ds.moderate(id, status);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Reviews'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filter == null,
                    onSelected: (_) {
                      setState(() => _filter = null);
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                  ...['pending', 'approved', 'rejected'].map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s),
                        selected: _filter == s,
                        onSelected: (_) {
                          setState(() => _filter = s);
                          _load();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? Center(
                  child: Text('No reviews', style: TextStyle(color: cs.onSurfaceVariant)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = _list[i];
                    final id = r['_id'].toString();
                    final rating = (r['rating'] as num?)?.toInt() ?? 0;
                    final status = r['status']?.toString() ?? '';
                    final user = r['user'] is Map ? r['user'] as Map : null;
                    final product = r['product'] is Map ? r['product'] as Map : null;
                    final name = user?['name']?.toString() ?? 'User';
                    final pname = product?['name']?.toString() ?? 'Product';
                    final title = r['title']?.toString() ?? '';
                    final body = r['body']?.toString() ?? '';
                    final created = r['createdAt']?.toString();
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$pname · $name',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(status, style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            Text('★' * rating + ' · $rating/5', style: TextStyle(color: cs.secondary)),
                            if (title.isNotEmpty) Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (body.isNotEmpty) Text(body),
                            if (created != null)
                              Builder(
                                builder: (_) {
                                  final dt = DateTime.tryParse(created);
                                  if (dt == null) return const SizedBox.shrink();
                                  return Text(
                                    fmt.format(dt.toLocal()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  );
                                },
                              ),
                            if (status == 'pending') ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  FilledButton(
                                    onPressed: () => _setStatus(id, 'approved'),
                                    child: const Text('Approve'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () => _setStatus(id, 'rejected'),
                                    child: const Text('Reject'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
