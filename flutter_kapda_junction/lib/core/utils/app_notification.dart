import 'dart:async';
import 'package:flutter/material.dart';

/// Top-slide notification banner.
/// Call [AppNotification.init] once at app start with the root navigator key.
class AppNotification {
  AppNotification._();

  static GlobalKey<NavigatorState>? _rootKey;
  static OverlayEntry? _active;
  static Timer? _timer;

  /// Call once in main.dart / app init with the root navigator key.
  static void init(GlobalKey<NavigatorState> key) => _rootKey = key;

  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, _Type.success);

  static void showInfo(BuildContext context, String message) =>
      _show(context, message, _Type.info);

  /// Foreground push notification banner — no BuildContext needed.
  /// Uses rootNavigatorKey overlay so it always works regardless of
  /// which page is currently active.
  static void showPush(String title, String body) {
    _dismiss();
    final overlay = _rootKey?.currentState?.overlay;
    debugPrint('[Notif] showPush called | rootKey=$_rootKey | overlay=$overlay');
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => _Banner(message: body, type: _Type.push, title: title),
    );
    _active = entry;
    overlay.insert(entry);
    _timer = Timer(const Duration(seconds: 5), _dismiss);
  }

  static void _show(BuildContext context, String message, _Type type) {
    _dismiss();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => _Banner(message: message, type: type),
    );
    _active = entry;
    overlay.insert(entry);
    _timer = Timer(const Duration(seconds: 3), _dismiss);
  }

  static void _dismiss() {
    _active?.remove();
    _active = null;
    _timer?.cancel();
    _timer = null;
  }
}

enum _Type { success, info, push }

class _Banner extends StatefulWidget {
  final String? title;
  final String message;
  final _Type type;
  const _Banner({required this.message, required this.type, this.title});

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  double _dragX = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == _Type.push) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SlideTransition(
          position: _slide,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) =>
                    setState(() => _dragX += d.delta.dx),
                onHorizontalDragEnd: (d) {
                  if (_dragX.abs() > 80) {
                    AppNotification._dismiss();
                  } else {
                    setState(() => _dragX = 0);
                  }
                },
                child: Transform.translate(
                  offset: Offset(_dragX, 0),
                  child: Opacity(
                    opacity: (1.0 - (_dragX.abs() / 220)).clamp(0.2, 1.0),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(80),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.notifications_rounded,
                                color: Color(0xFFF59E0B),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.title != null &&
                                      widget.title!.isNotEmpty)
                                    Text(
                                      widget.title!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (widget.title != null &&
                                      widget.title!.isNotEmpty)
                                    const SizedBox(height: 2),
                                  Text(
                                    widget.message,
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(200),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ── success / info banners ────────────────────────────────────────────────
    final (bg, icon) = switch (widget.type) {
      _Type.success => (const Color(0xFF059669), Icons.check_circle_rounded),
      _Type.info    => (const Color(0xFF0F172A), Icons.info_rounded),
      _Type.push    => (const Color(0xFF0F172A), Icons.notifications_rounded),
    };

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
