import 'dart:async';
import 'package:flutter/material.dart';

/// Top-slide notification banner. Use [AppNotification.showSuccess] for
/// success feedback and [AppNotification.showInfo] for neutral info.
/// For backend / validation errors use [AppErrorHandler.show] instead.
class AppNotification {
  AppNotification._();

  static OverlayEntry? _active;
  static Timer? _timer;

  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, _Type.success);

  static void showInfo(BuildContext context, String message) =>
      _show(context, message, _Type.info);

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

enum _Type { success, info }

class _Banner extends StatefulWidget {
  final String message;
  final _Type type;
  const _Banner({required this.message, required this.type});

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
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
    final (bg, icon) = switch (widget.type) {
      _Type.success => (const Color(0xFF059669), Icons.check_circle_rounded),
      _Type.info => (const Color(0xFF0F172A), Icons.info_rounded),
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
