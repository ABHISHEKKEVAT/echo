import 'package:dio/dio.dart';

typedef TokenProvider = Future<String?> Function();
typedef MissingTokenExceptionFactory = Object Function();

class AuthenticatedApiClient {
  AuthenticatedApiClient({
    required String baseUrl,
    required TokenProvider getAccessToken,
    required MissingTokenExceptionFactory onMissingToken,
    TokenProvider? refreshAccessToken,
    Dio? dio,
  }) : _baseUrl = baseUrl,
       _getAccessToken = getAccessToken,
       _refreshAccessToken = refreshAccessToken,
       _onMissingToken = onMissingToken,
       _dio = dio ?? Dio();

  final String _baseUrl;
  final TokenProvider _getAccessToken;
  final TokenProvider? _refreshAccessToken;
  final MissingTokenExceptionFactory _onMissingToken;
  final Dio _dio;

  String path(String suffix) => '$_baseUrl$suffix';

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _withAuthRetry(
      (options) =>
          _dio.get(path, queryParameters: queryParameters, options: options),
    );
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _withAuthRetry(
      (options) => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _withAuthRetry(
      (options) => _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _withAuthRetry(
      (options) => _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<dynamic>> _withAuthRetry(
    Future<Response<dynamic>> Function(Options options) request,
  ) async {
    try {
      return await request(await _authOptions());
    } on DioException catch (e) {
      if (e.response?.statusCode != 401 || _refreshAccessToken == null) {
        rethrow;
      }

      final refreshedToken = await _refreshAccessToken();
      if (refreshedToken == null || refreshedToken.isEmpty) {
        rethrow;
      }

      return request(_tokenOptions(refreshedToken));
    }
  }

  Future<Options> _authOptions() async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      throw _onMissingToken();
    }
    return _tokenOptions(token);
  }

  Options _tokenOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
