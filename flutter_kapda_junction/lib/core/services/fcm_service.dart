import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';
import '../di/injection.dart';

/// FCM service. Works only after Firebase.initializeApp() succeeds.
/// All methods are silent no-ops if Firebase isn't configured.
class FcmService {
  static bool _ready = false;
  static void Function(String productId)? _openProductHandler;
  static String? _pendingProductId;

  static void Function(Map<String, String> data)? _routeFromPush;
  static Map<String, String>? _pendingPushRoute;

  static void Function(String title, String body)? _foregroundHandler;

  static void markReady() => _ready = true;

  static void setOpenProductHandler(void Function(String productId) handler) {
    _openProductHandler = handler;
    final pending = _pendingProductId;
    if (pending != null) {
      _pendingProductId = null;
      handler(pending);
    }
  }

  /// Called by a widget with BuildContext to show an in-app banner for foreground messages.
  static void setForegroundHandler(void Function(String title, String body) handler) {
    _foregroundHandler = handler;
  }

  /// Order / returns notifications include `screen` + ids in data payload.
  static void setRouteFromPushHandler(void Function(Map<String, String> data) handler) {
    _routeFromPush = handler;
    final pending = _pendingPushRoute;
    if (pending != null) {
      _pendingPushRoute = null;
      handler(pending);
    }
  }

  /// Called from SplashPage when user taps "Allow Notifications".
  /// Requests OS permission, sets up listeners, and registers token anonymously.
  static Future<void> init() async {
    if (!_ready) return;
    try {
      final m = FirebaseMessaging.instance;
      await m.requestPermission(alert: true, badge: true, sound: true);
      m.onTokenRefresh.listen(_uploadAnonymous);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);
      final initial = await m.getInitialMessage();
      if (initial != null) _handleMessageOpen(initial);
      // Register current token anonymously (user may not be logged in yet)
      await registerAnonymousToken();
    } catch (e) {
      debugPrint('[FCM] init: $e');
    }
  }

  /// Registers FCM token under the anonymous device identity (no auth needed).
  /// Safe to call before login — backend stores it in DeviceToken collection.
  static Future<void> registerAnonymousToken() async {
    if (!_ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _uploadAnonymous(token);
    } catch (e) {
      debugPrint('[FCM] registerAnonymousToken: $e');
    }
  }

  /// Registers FCM token under the authenticated user account.
  /// Backend moves the token from DeviceToken → User.fcmTokens.
  static Future<void> registerToken() async {
    if (!_ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _uploadAuthenticated(token);
    } catch (e) {
      debugPrint('[FCM] registerToken: $e');
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;
    _foregroundHandler?.call(title, body);
  }

  static Future<void> _uploadAuthenticated(String token) async {
    try {
      await sl<ApiClient>().post(ApiConstants.fcmToken, data: {
        'token': token,
        'platform': defaultTargetPlatform.name.toLowerCase(),
      });
    } catch (_) {}
  }

  static Future<void> _uploadAnonymous(String token) async {
    try {
      final deviceId = await sl<LocalStorage>().getOrCreateDeviceId();
      await sl<ApiClient>().post(ApiConstants.deviceRegisterToken, data: {
        'deviceId': deviceId,
        'token': token,
        'platform': defaultTargetPlatform.name.toLowerCase(),
      });
    } catch (_) {}
  }

  static void _handleMessageOpen(RemoteMessage message) {
    final data = <String, String>{};
    for (final e in message.data.entries) {
      data[e.key] = e.value?.toString() ?? '';
    }

    final screen = data['screen']?.trim() ?? '';
    if (screen == 'order' && (data['orderId'] ?? '').isNotEmpty) {
      if (_routeFromPush != null) {
        _routeFromPush!(data);
      } else {
        _pendingPushRoute = Map<String, String>.from(data);
      }
      return;
    }
    if (screen == 'returns') {
      if (_routeFromPush != null) {
        _routeFromPush!(data);
      } else {
        _pendingPushRoute = Map<String, String>.from(data);
      }
      return;
    }

    String? productId = data['productId']?.isNotEmpty == true ? data['productId'] : null;
    productId ??= _extractProductIdFromUrl(data['shareUrl']);

    if (productId == null || productId.isEmpty) return;
    if (_openProductHandler != null) {
      _openProductHandler!(productId);
    } else {
      _pendingProductId = productId;
    }
  }

  static String? _extractProductIdFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final marker = '/share/product/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    final part = url.substring(idx + marker.length);
    if (part.isEmpty) return null;
    return part.split('?').first.split('#').first;
  }
}
