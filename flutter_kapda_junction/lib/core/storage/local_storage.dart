import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../../data/models/user_model.dart';

class LocalStorage {
  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  Future<void> saveToken(String token) =>
      _prefs.setString(AppConstants.tokenKey, token);

  Future<String?> getToken() async => _prefs.getString(AppConstants.tokenKey);

  Future<void> clearToken() => _prefs.remove(AppConstants.tokenKey);

  Future<void> saveUser(Map<String, dynamic> user) =>
      _prefs.setString(AppConstants.userKey, jsonEncode(user));

  Future<Map<String, dynamic>?> getUser() async {
    final raw = _prefs.getString(AppConstants.userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<UserModel?> getSavedUserModel() async {
    final user = await getUser();
    if (user == null) return null;
    return UserModel.fromJson(user);
  }

  Future<void> clearUser() => _prefs.remove(AppConstants.userKey);

  Future<void> saveCartItems(List<Map<String, dynamic>> items) =>
      _prefs.setString(AppConstants.cartItemsKey, jsonEncode(items));

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final raw = _prefs.getString(AppConstants.cartItemsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> clearCart() => _prefs.remove(AppConstants.cartItemsKey);

  Future<void> clearAll() => _prefs.clear();

  // ── Anonymous device identity ─────────────────────────────────────────────

  /// Returns a stable UUID for this device, generating one on first call.
  Future<String> getOrCreateDeviceId() async {
    const key = 'device_id';
    var id = _prefs.getString(key);
    if (id == null) {
      id = _generateUuidV4();
      await _prefs.setString(key, id);
    }
    return id;
  }

  static String _generateUuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
  }

  // ── Notification permission state ─────────────────────────────────────────

  /// True if the user has already seen the notification permission card.
  bool get notifPermissionShown => _prefs.getBool('notif_permission_shown') ?? false;

  /// True if the user previously allowed notifications.
  bool get notifPermissionGranted => _prefs.getBool('notif_permission_granted') ?? false;

  Future<void> saveNotifPermission({required bool granted}) async {
    await _prefs.setBool('notif_permission_shown', true);
    await _prefs.setBool('notif_permission_granted', granted);
  }
}
