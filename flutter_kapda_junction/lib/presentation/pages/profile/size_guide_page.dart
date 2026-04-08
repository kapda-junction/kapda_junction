import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../core/di/injection.dart';
import '../../../data/datasources/remote/home_remote_datasource.dart';

class SizeGuidePage extends StatefulWidget {
  const SizeGuidePage({super.key});

  @override
  State<SizeGuidePage> createState() => _SizeGuidePageState();
}

class _SizeGuidePageState extends State<SizeGuidePage> {
  String _html = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final m = await sl<HomeRemoteDataSource>().getSettings();
      if (!mounted) return;
      setState(() {
        _html = (m['sizeGuideHtml'] ?? '').toString();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Size guide')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: cs.error)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _html.trim().isEmpty
                        ? Text(
                            'No size guide has been set yet. Check back later.',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          )
                        : Html(data: _html),
                  ),
                ),
    );
  }
}
