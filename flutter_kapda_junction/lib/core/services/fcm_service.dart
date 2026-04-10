import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';
import '../di/injection.dart';
import '../utils/app_notification.dart';

/// FCM service. Works only after Firebase.initializeApp() succeeds.
/// All methods are silent no-ops if Firebase isn't configured.
class FcmService {
  static bool _ready = false;
  static bool _initialized = false; // guard against double-init
  static void Function(String productId)? _openProductHandler;
  static String? _pendingProductId;

  static void Function(Map<String, String> data)? _routeFromPush;
  static Map<String, String>? _pendingPushRoute;

  /// Route to navigate to after splash, set when app is launched by tapping a notification.
  static String? _initialRouteOverride;
  static String? consumeInitialRouteOverride() {
    final r = _initialRouteOverride;
    _initialRouteOverride = null;
    return r;
  }

  static void markReady() => _ready = true;

  static void setOpenProductHandler(void Function(String productId) handler) {
    _openProductHandler = handler;
    final pending = _pendingProductId;
    if (pending != null) {
      _pendingProductId = null;
      handler(pending);
    }
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
    if (_initialized) return; // prevent duplicate listeners
    _initialized = true;
    try {
      final m = FirebaseMessaging.instance;
      await m.requestPermission(alert: true, badge: true, sound: true);
      m.onTokenRefresh.listen(_uploadAnonymous);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      debugPrint('[FCM] onMessage listener registered');
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);
      final initial = await m.getInitialMessage();
      if (initial != null) {
        // Store the target route — SplashPage will navigate there after auth check
        // instead of going to '/'. This prevents SplashPage from overwriting the
        // product/order route that would otherwise fire immediately here.
        _initialRouteOverride = _buildRouteFromMessage(initial);
      }
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

  static String? _buildRouteFromMessage(RemoteMessage message) {
    final data = <String, String>{};
    for (final e in message.data.entries) {
      data[e.key] = e.value?.toString() ?? '';
    }
    final screen = data['screen']?.trim() ?? '';
    if (screen == 'order' && (data['orderId'] ?? '').isNotEmpty) {
      return '/orders/${data['orderId']}';
    }
    if (screen == 'returns') return '/returns';
    String? productId = data['productId']?.isNotEmpty == true ? data['productId'] : null;
    productId ??= _extractProductIdFromUrl(data['shareUrl']);
    if (productId != null && productId.isNotEmpty) {
      return '/product/$productId?fromPush=1';
    }
    return null;
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] foreground message: ${message.notification?.title}');
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;
    AppNotification.showPush(title, body);
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
