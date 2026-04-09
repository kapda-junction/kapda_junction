import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';

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
    final accent = const Color(0xFFF59E0B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Size guide'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black12,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outlineVariant.withAlpha(128)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: cs.error)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: accent,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        child: _html.trim().isEmpty
                            ? Text(
                                'No size guide has been set yet. Check back later.',
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: cs.outline.withAlpha(60),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(10),
                                          blurRadius: 20,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: accent.withAlpha(35),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.straighten_rounded,
                                            color: accent,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Find your fit',
                                            style: tt.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: ColoredBox(
                                      color: Colors.white,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          14,
                                          14,
                                          18,
                                        ),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: constraints.maxWidth -
                                                32,
                                          ),
                                          child: Html(
                                            data: _html,
                                            shrinkWrap: true,
                                            extensions: const [
                                              TableHtmlExtension(),
                                            ],
                                            style: {
                                              'body': Style(
                                                margin: Margins.zero,
                                              ),
                                              'h2': Style(
                                                fontSize: FontSize(20),
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF0F172A),
                                                margin: Margins.only(bottom: 8),
                                              ),
                                              'h3': Style(
                                                fontSize: FontSize(15),
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF0F172A),
                                                margin: Margins.only(
                                                  top: 18,
                                                  bottom: 10,
                                                ),
                                              ),
                                              'p': Style(
                                                fontSize: FontSize(14),
                                                color: cs.onSurfaceVariant,
                                                lineHeight: LineHeight(1.45),
                                                margin: Margins.only(bottom: 4),
                                              ),
                                              'strong': Style(
                                                color: const Color(0xFF0F172A),
                                                fontWeight: FontWeight.w700,
                                              ),
                                              'table': Style(
                                                border: Border.all(
                                                  color: cs.outline
                                                      .withAlpha(100),
                                                ),
                                                margin: Margins.zero,
                                              ),
                                              'tr': Style(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: cs.outline
                                                        .withAlpha(70),
                                                  ),
                                                ),
                                              ),
                                              'th': Style(
                                                padding: HtmlPaddings.symmetric(
                                                  horizontal: 10,
                                                  vertical: 10,
                                                ),
                                                fontSize: FontSize(11.5),
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF0F172A),
                                                backgroundColor:
                                                    const Color(0xFFF1F5F9),
                                                border: Border(
                                                  right: BorderSide(
                                                    color: cs.outline
                                                        .withAlpha(60),
                                                  ),
                                                ),
                                                textAlign: TextAlign.left,
                                              ),
                                              'td': Style(
                                                padding: HtmlPaddings.symmetric(
                                                  horizontal: 10,
                                                  vertical: 10,
                                                ),
                                                fontSize: FontSize(13.5),
                                                color: cs.onSurface,
                                                border: Border(
                                                  right: BorderSide(
                                                    color: cs.outline
                                                        .withAlpha(50),
                                                  ),
                                                ),
                                                textAlign: TextAlign.left,
                                              ),
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
    );
  }
}
