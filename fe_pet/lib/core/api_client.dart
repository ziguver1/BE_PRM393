import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  String? Function()? _tokenGetter;

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
      onError: (DioException e, handler) {
        String message = 'Đã xảy ra lỗi kết nối';
        
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          message = 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng hoặc backend.';
        } else if (e.response != null) {
          final status = e.response!.statusCode;
          final errorData = e.response!.data;
          
          if (errorData is Map && errorData.containsKey('error')) {
            message = errorData['error'].toString();
          } else if (errorData is Map && errorData.containsKey('message')) {
            message = errorData['message'].toString();
          } else {
            switch (status) {
              case 400:
                message = 'Yêu cầu không hợp lệ (lỗi cú pháp hoặc hết hàng)';
                break;
              case 401:
                message = 'Phiên đăng nhập hết hạn hoặc chưa đăng nhập';
                break;
              case 403:
                message = 'Bạn không có quyền thực hiện thao tác này';
                break;
              case 404:
                message = 'Không tìm thấy dữ liệu yêu cầu';
                break;
              case 409:
                message = 'Dữ liệu bị trùng lặp hoặc xung đột';
                break;
              case 500:
                message = 'Lỗi hệ thống phía máy chủ';
                break;
            }
          }
        }
        
        return handler.next(DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: e.type,
          error: message,
        ));
      },
    ));
  }

  void init({required String? Function() tokenGetter}) {
    _tokenGetter = tokenGetter;
  }

  static String getBaseUrl() {
    // Hardcode localhost:3000 for local backend
    if (kIsWeb) return 'http://localhost:3000/api';
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:3000/api';
      }
    } catch (_) {}
    return 'http://localhost:3000/api';
  }
}
