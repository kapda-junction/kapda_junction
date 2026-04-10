import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _client;
  AuthRemoteDataSource(this._client);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _client.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
      skipGlobalError: true, // auth bloc handles and shows popup
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final res = await _client.post(
      ApiConstants.register,
      data: {'name': name, 'email': email, 'password': password},
      skipGlobalError: true, // auth bloc handles and shows popup
    );
    return res.data as Map<String, dynamic>;
  }

  Future<UserModel> getMe() async {
    final res = await _client.get(ApiConstants.me);
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }
}
