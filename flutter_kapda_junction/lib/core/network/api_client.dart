import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import '../error/app_error_handler.dart';
import '../storage/local_storage.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient(LocalStorage localStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // JWT interceptor + global error handler
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await localStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.requestOptions.extra['skipGlobalError'] != true) {
            AppErrorHandler.handleDioError(error);
          }
          handler.next(error);
        },
      ),
    );

    // Request/Response logger — terminal mein dikh jaayega
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: false,
        responseBody: false,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? params,
    bool skipGlobalError = false,
  }) =>
      _dio.get(
        path,
        queryParameters: params,
        options: skipGlobalError
            ? Options(extra: const {'skipGlobalError': true})
            : null,
      );

  Future<Response> post(
    String path, {
    dynamic data,
    bool skipGlobalError = false,
  }) =>
      _dio.post(
        path,
        data: data,
        options: skipGlobalError
            ? Options(extra: const {'skipGlobalError': true})
            : null,
      );

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  /// Customer return proof — multipart video to Cloudinary.
  Future<String> uploadReturnVideo(String filePath) async {
    final form = FormData.fromMap({
      'video': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post(
      '${ApiConstants.upload}/return-video',
      data: form,
      options: Options(
        receiveTimeout: const Duration(minutes: 4),
        sendTimeout: const Duration(minutes: 4),
      ),
    );
    final data = res.data as Map<String, dynamic>;
    return data['url'] as String;
  }
}
