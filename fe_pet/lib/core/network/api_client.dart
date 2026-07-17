import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  String? Function()? _tokenGetter;
  String? Function()? _refreshTokenGetter;
  Future<bool> Function(String newAccessToken, String newRefreshToken)? _onTokenRefreshed;
  void Function()? _onLogoutRequired;

  String? get token => _tokenGetter?.call();
  
  bool _isRefreshing = false;
  final List<void Function(String token)> _failedQueue = [];

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.baseUrl.isEmpty) {
          options.baseUrl = getBaseUrl();
        }

        if (_tokenGetter != null) {
          final token = _tokenGetter!();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Trigger Token Refresh if status is 401 Unauthorized
        if (e.response?.statusCode == 401 && _refreshTokenGetter != null) {
          final requestPath = e.requestOptions.path;
          
          // Skip refresh logic for actual auth paths
          if (!requestPath.contains('/auth/login') &&
              !requestPath.contains('/auth/register') &&
              !requestPath.contains('/auth/refresh')) {
            
            return _handleRefreshToken(e, handler);
          }
        }

        String message = _translateError(e);
        return handler.next(DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: e.type,
          error: message,
        ));
      },
    ));
  }

  void init({
    required String? Function() tokenGetter,
    required String? Function() refreshTokenGetter,
    required Future<bool> Function(String, String) onTokenRefreshed,
    required void Function() onLogoutRequired,
  }) {
    _tokenGetter = tokenGetter;
    _refreshTokenGetter = refreshTokenGetter;
    _onTokenRefreshed = onTokenRefreshed;
    _onLogoutRequired = onLogoutRequired;
  }

  Future<void> _handleRefreshToken(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    if (_isRefreshing) {
      // Queue requests until refresh completes
      _failedQueue.add((newToken) {
        requestOptions.headers['Authorization'] = 'Bearer $newToken';
        dio.fetch(requestOptions).then(
          (response) => handler.resolve(response),
          onError: (retryErr) => handler.next(retryErr),
        );
      });
      return;
    }

    _isRefreshing = true;
    final currentRefreshToken = _refreshTokenGetter?.call();

    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      _isRefreshing = false;
      _onLogoutRequired?.call();
      return handler.next(err);
    }

    try {
      // Create separate Dio client for refresh to prevent interceptor loop
      final refreshDio = Dio(BaseOptions(
        baseUrl: getBaseUrl(),
        connectTimeout: const Duration(seconds: 10),
      ));

      final response = await refreshDio.post('/auth/refresh', data: {
        'RefreshToken': currentRefreshToken,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newAccess = response.data['accessToken'];
        final newRefresh = response.data['refreshToken'];

        if (newAccess != null && newRefresh != null) {
          final isSaved = await _onTokenRefreshed?.call(newAccess, newRefresh) ?? false;
          if (isSaved) {
            requestOptions.headers['Authorization'] = 'Bearer $newAccess';
            
            // Flush waiting requests in queue
            for (final callback in _failedQueue) {
              callback(newAccess);
            }
            _failedQueue.clear();

            _isRefreshing = false;
            
            // Retry original request
            final retriedResponse = await dio.fetch(requestOptions);
            return handler.resolve(retriedResponse);
          }
        }
      }
    } catch (refreshErr) {
      _failedQueue.clear();
      _isRefreshing = false;
      _onLogoutRequired?.call();
      return handler.next(err);
    }

    _failedQueue.clear();
    _isRefreshing = false;
    _onLogoutRequired?.call();
    return handler.next(err);
  }

  String _translateError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng hoặc backend.';
    }
    if (e.response != null) {
      final status = e.response!.statusCode;
      final errorData = e.response!.data;
      
      if (errorData is Map) {
        if (errorData.containsKey('error')) {
          return errorData['error'].toString();
        }
        if (errorData.containsKey('message')) {
          if (errorData['message'] is List) {
            return (errorData['message'] as List).join('\n');
          }
          return errorData['message'].toString();
        }
      }
      
      switch (status) {
        case 400: return 'Yêu cầu không hợp lệ (lỗi cú pháp hoặc hết hàng)';
        case 401: return 'Phiên đăng nhập hết hạn hoặc chưa đăng nhập';
        case 403: return 'Bạn không có quyền thực hiện thao tác này';
        case 404: return 'Không tìm thấy dữ liệu yêu cầu';
        case 409: return 'Dữ liệu bị trùng lặp hoặc xung đột';
        case 500: return 'Lỗi hệ thống phía máy chủ';
      }
    }
    return 'Đã xảy ra lỗi kết nối';
  }

  static String getBaseUrl() {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    return ApiConstants.apiBaseUrl;
  }
}
