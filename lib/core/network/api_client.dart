import 'package:dio/dio.dart';
import 'package:kaamfast/common/app_constants.dart';
import 'package:kaamfast/core/network/api_exception.dart';
import 'package:kaamfast/core/storage/token_storage.dart';

class ApiClient {
  ApiClient(this._tokens) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokens.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  final TokenStorage _tokens;
  late final Dio _dio;

  Dio get raw => _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _unwrap(() => _dio.get(path, queryParameters: query));
  }

  Future<dynamic> post(String path, {Object? data}) async {
    return _unwrap(() => _dio.post(path, data: data));
  }

  Future<dynamic> put(String path, {Object? data}) async {
    return _unwrap(() => _dio.put(path, data: data));
  }

  Future<dynamic> delete(String path) async {
    return _unwrap(() => _dio.delete(path));
  }

  Future<dynamic> postMultipart(String path, FormData data) async {
    return _unwrap(
      () => _dio.post(
        path,
        data: data,
        options: Options(contentType: 'multipart/form-data'),
      ),
    );
  }

  Future<dynamic> _unwrap(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final body = response.data;
      if (body is Map<String, dynamic>) {
        if (body['success'] == false) {
          throw ApiException(
            body['message']?.toString() ?? 'Request failed',
            statusCode: response.statusCode,
            errors: body['errors'],
          );
        }
        return body['data'];
      }
      return body;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw ApiException(
          data['message'].toString(),
          statusCode: e.response?.statusCode,
          errors: data['errors'],
        );
      }
      throw ApiException(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
