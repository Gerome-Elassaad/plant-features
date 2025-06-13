import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:aspargo/core/constants/api_constants.dart';
import 'package:aspargo/core/exceptions/app_execptions.dart'; // Corrected path and reflects filename typo

class ApiService {
  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;
  ApiService._internal();
  
  late Dio _dio;
  late CacheOptions _cacheOptions;
  
  void init() {
    _cacheOptions = CacheOptions(
      store: MemCacheStore(),
      policy: CachePolicy.refreshForceCache, // Changed from requestFirst
      maxStale: const Duration(minutes: 5),
      priority: CachePriority.normal,
      cipher: null,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
      allowPostMethod: false,
    );
    
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors
    _dio.interceptors.addAll([
      DioCacheInterceptor(options: _cacheOptions),
      _ErrorInterceptor(),
      // Add logger only in debug mode
      if (ApiConstants.enableLogging)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
    ]);
  }
  
  // GET request
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data!;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // POST request
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data!;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // POST with FormData (for file uploads)
  Future<T> postFormData<T>(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options ?? Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onSendProgress,
      );
      return response.data!;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // PUT request
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data!;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // DELETE request
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data!;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Clear cache
  Future<void> clearCache() async {
    await _cacheOptions.store?.clean();
  }
  
  // Handle errors
  AppException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout. Please try again.');
        
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = error.response?.data?['error']?['message'] ?? 
                        error.response?.data?['message'] ?? 
                        'An error occurred';
        
        if (statusCode == 400) {
          return BadRequestException(message);
        } else if (statusCode == 401) {
          return UnauthorizedException(message);
        } else if (statusCode == 404) {
          return NotFoundException(message);
        } else if (statusCode == 429) {
          return RateLimitException(message);
        } else if (statusCode >= 500) {
          return ServerException(message);
        }
        return AppException(message);
        
      case DioExceptionType.cancel:
        return AppException('Request cancelled');
        
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NetworkException('No internet connection');
        }
        return AppException('An unexpected error occurred');
        
      default:
        return AppException('An error occurred');
    }
  }
}

// Error interceptor
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log error details only if logging is enabled
    if (ApiConstants.enableLogging) {
      if (kDebugMode) {
        print('API Error: ${err.message}');
      }
      if (kDebugMode) {
        print('API Error Type: ${err.type}');
      }
      if (kDebugMode) {
        print('API Error Response: ${err.response?.data}');
      }
    }
    
    handler.next(err);
  }
}
