import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class UploadDataSource {
  final ApiClient _client;
  UploadDataSource(this._client);

  Future<String> uploadProductImage(String filePath) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    final res = await _client.postForm(ApiConstants.uploadImage, form);
    final data = res.data as Map<String, dynamic>;
    return data['url'] as String;
  }

  Future<String> uploadBannerImage(String filePath) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    final res = await _client.postForm(ApiConstants.uploadBanner, form);
    final data = res.data as Map<String, dynamic>;
    return data['url'] as String;
  }
}
