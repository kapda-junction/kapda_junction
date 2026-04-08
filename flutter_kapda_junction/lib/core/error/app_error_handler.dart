import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Global error handler — call [AppErrorHandler.init] once with the router's
/// navigator key, then any Dio error (or manual [show] call) pops a modal.
class AppErrorHandler {
  AppErrorHandler._();

  static GlobalKey<NavigatorState>? _key;
  static bool _isShowing = false;

  static void init(GlobalKey<NavigatorState> navigatorKey) {
    _key = navigatorKey;
  }

  /// Called by the Dio interceptor for every failed request.
  static void handleDioError(DioException error) {
    final code = error.response?.statusCode;
    // 401 is handled by auth redirect — skip it
    if (code == 401) return;
    show(_extractMessage(error), title: _titleFor(error));
  }

  /// Show an error modal from anywhere in the app.
  static void show(String message, {String? title}) {
    if (_isShowing) return;
    final ctx = _key?.currentContext;
    if (ctx == null) return;

    _isShowing = true;
    showDialog<void>(
      context: ctx,
      barrierDismissible: true,
      builder: (_) => _ErrorDialog(title: title ?? 'Error', message: message),
    ).whenComplete(() => _isShowing = false);
  }

  static String _extractMessage(DioException error) {
    try {
      final data = error.response?.data;
      if (data is Map) {
        final msg = data['message'] ?? data['error'] ?? data['msg'];
        if (msg != null && msg.toString().isNotEmpty) return msg.toString();
      }
    } catch (_) {}

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please try again.';
      default:
        final code = error.response?.statusCode;
        if (code != null && code >= 500) return 'Server error. Please try again later.';
        return 'Something went wrong. Please try again.';
    }
  }

  static String _titleFor(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Connection Error';
      default:
        final code = error.response?.statusCode;
        if (code != null && code >= 500) return 'Server Error';
        return 'Error';
    }
  }
}

class _ErrorDialog extends StatelessWidget {
  final String title;
  final String message;

  const _ErrorDialog({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
