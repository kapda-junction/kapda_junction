import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../models/user_model.dart';

class AuthDataSource {
  final ApiClient _client;
  final LocalStorage _storage;
  AuthDataSource(this._client, this._storage);

  Future<({AdminUserModel user, String token})> login(String email, String password) async {
    final res = await _client.post(ApiConstants.login, data: {'email': email, 'password': password});
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = AdminUserModel.fromJson(data['user'] as Map<String, dynamic>);
    if (!user.isAdmin) throw Exception('Access denied: admin role required');
    await _storage.saveToken(token);
    await _storage.saveUserJson(user.toJson().toString());
    return (user: user, token: token);
  }

  Future<AdminUserModel> getMe() async {
    final res = await _client.get(ApiConstants.me);
    return AdminUserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout() => _storage.clearAll();
}
