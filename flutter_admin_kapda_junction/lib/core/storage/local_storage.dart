import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class LocalStorage {
  final SharedPreferences _prefs;
  LocalStorage(this._prefs);

  String? getToken()        => _prefs.getString(AppConstants.tokenKey);
  Future<void> saveToken(String t) => _prefs.setString(AppConstants.tokenKey, t);
  Future<void> clearToken()        => _prefs.remove(AppConstants.tokenKey);

  String? getUserJson()           => _prefs.getString(AppConstants.userKey);
  Future<void> saveUserJson(String j) => _prefs.setString(AppConstants.userKey, j);
  Future<void> clearUser()            => _prefs.remove(AppConstants.userKey);

  Future<void> clearAll() async {
    await clearToken();
    await clearUser();
  }
}
