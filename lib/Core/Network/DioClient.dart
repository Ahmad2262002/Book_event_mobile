import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DioClient {
  String? token;
  final Duration _connectTimeout;
  final Duration _receiveTimeout;
  final Duration _sendTimeout;
  final int _maxRetries;
  final Duration _retryDelay;
  final bool _enableCircuitBreaker;
  final Duration _circuitBreakerCooldown;

  late Dio _dio;
  final Connectivity _connectivity = Connectivity();
  bool _circuitOpen = false;
  DateTime? _lastFailureTime;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  DioClient({
    this.token,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    int? maxRetries,
    Duration? retryDelay,
    bool? enableCircuitBreaker,
    Duration? circuitBreakerCooldown,
  })  : _connectTimeout = connectTimeout ?? const Duration(seconds: 45),
        _receiveTimeout = receiveTimeout ?? const Duration(seconds: 45),
        _sendTimeout = sendTimeout ?? const Duration(seconds: 45),
        _maxRetries = maxRetries ?? 3,
        _retryDelay = retryDelay ?? const Duration(seconds: 2),
        _enableCircuitBreaker = enableCircuitBreaker ?? true,
        _circuitBreakerCooldown = circuitBreakerCooldown ?? const Duration(minutes: 1) {
    _initDio();
    _checkInitialConnectivity();
    _startConnectivityMonitoring();
  }

  Dio get instance => _dio;

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://172.20.10.3:8000/api',
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout: _sendTimeout,
        headers: _getDefaultHeaders(),
        persistentConnection: true,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.addAll([
      _createRetryInterceptor(),
      if (kDebugMode) _createLoggerInterceptor(),
    ]);
  }

  Map<String, String> _getDefaultHeaders() {
    return {
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip',
      'Connection': 'keep-alive',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== HEADER HELPERS ====================

  Map<String, String> _getJsonHeaders() {
    return {
      ..._getDefaultHeaders(),
      'Content-Type': 'application/json',
    };
  }

  Map<String, String> _getMultipartHeaders() {
    return {
      ..._getDefaultHeaders(),
      // Content-Type will be set automatically by Dio with boundary
    };
  }

  // ==================== API METHODS ====================

  Future<ApiResponse<T>> get<T>(
      String path, {
        Map<String, dynamic>? queryParams,
        required T Function(Map<String, dynamic> json) fromJsonT,
      }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParams,
        options: Options(headers: _getJsonHeaders()),
      );
      return _parseResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResponse<T>> post<T>(
      String path, {
        dynamic data,
        required T Function(Map<String, dynamic> json) fromJsonT,
        bool isMultipart = false,
      }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: Options(
          headers: isMultipart ? _getMultipartHeaders() : _getJsonHeaders(),
        ),
      );
      return _parseResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResponse<T>> put<T>(
      String path, {
        dynamic data,
        required T Function(Map<String, dynamic> json) fromJsonT,
        bool isMultipart = false,
      }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        options: Options(
          headers: isMultipart ? _getMultipartHeaders() : _getJsonHeaders(),
        ),
      );
      return _parseResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResponse<T>> delete<T>(
      String path, {
        dynamic data,
        required T Function(Map<String, dynamic> json) fromJsonT,
      }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        options: Options(headers: _getJsonHeaders()),
      );
      return _parseResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResponse<T>> upload<T>(
      String path, {
        required FormData formData,
        required T Function(Map<String, dynamic> json) fromJsonT,
        ProgressCallback? onSendProgress,
      }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(headers: _getMultipartHeaders()),
      );
      return _parseResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // ==================== RESPONSE HANDLING ====================

  ApiResponse<T> _parseResponse<T>(
      Response response,
      T Function(Map<String, dynamic> json) fromJsonT,
      ) {
    try {
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        // Handle both response formats:
        // 1. With success flag: {"success": true, "data": {...}, "message": ""}
        // 2. Direct data response: {"id": 1, "title": "Event", ...}
        if (responseData.containsKey('success')) {
          return ApiResponse<T>(
            success: responseData['success'] ?? false,
            message: responseData['message'],
            data: responseData['data'] != null
                ? fromJsonT(responseData['data'] ?? responseData)
                : null,
          );
        } else {
          return ApiResponse<T>(
            success: true,
            data: fromJsonT(responseData),
          );
        }
      } else {
        return ApiResponse<T>(
          success: false,
          message: 'Invalid response format',
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Failed to parse response: $e',
      );
    }
  }

  ApiResponse<T> _handleError<T>(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      _activateCircuitBreaker();
    }

    if (e.response != null) {
      try {
        return ApiResponse<T>.fromJson(
          e.response?.data ?? {},
              (json) => null as T, // Cast to T, will be null anyway
        );
      } catch (_) {
        return ApiResponse<T>(
          success: false,
          message: e.message ?? 'Request failed',
        );
      }
    } else {
      return ApiResponse<T>(
        success: false,
        message: e.message ?? 'Network error occurred',
      );
    }
  }

  // ==================== NETWORK MANAGEMENT ====================

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _logConnectivity(result);

      if (result == ConnectivityResult.none) {
        _activateCircuitBreaker();
        throw DioException(
          requestOptions: RequestOptions(path: '/'),
          error: 'No internet connection available',
          type: DioExceptionType.connectionError,
        );
      }
    } catch (e) {
      _activateCircuitBreaker();
      rethrow;
    }
  }

  void _logConnectivity(ConnectivityResult result) {
    if (kDebugMode) {
      print('📡 Connectivity changed: $result');
      if (result == ConnectivityResult.none) {
        print('⚠️ No internet connection!');
      } else {
        print('✅ Back online: $result');
      }
    }
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
          final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
          _logConnectivity(result);

          if (result != ConnectivityResult.none) {
            if (_circuitOpen &&
                _lastFailureTime != null &&
                DateTime.now().difference(_lastFailureTime!) >= _circuitBreakerCooldown) {
              _circuitOpen = false;
              if (kDebugMode) print('🔄 Circuit breaker reset due to restored connection.');
            }
          } else {
            _activateCircuitBreaker();
          }
        });
  }

  Interceptor _createRetryInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_circuitOpen) {
          return handler.reject(DioException(
            requestOptions: options,
            error: 'Service temporarily unavailable. Please try again later.',
          ));
        }

        if (options.data is! FormData) {
          try {
            final results = await _connectivity.checkConnectivity();
            final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
            if (result == ConnectivityResult.none) {
              _activateCircuitBreaker();
              return handler.reject(DioException(
                requestOptions: options,
                error: 'No internet connection available',
                type: DioExceptionType.connectionError,
              ));
            }
          } catch (e) {
            _activateCircuitBreaker();
            return handler.reject(DioException(
              requestOptions: options,
              error: 'Network connectivity check failed',
              type: DioExceptionType.connectionError,
            ));
          }
        }

        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.requestOptions.data is FormData) {
          return handler.next(error);
        }

        if (!_shouldRetry(error)) {
          return handler.next(error);
        }

        final retryCount = (error.requestOptions.extra['retryCount'] as int?) ?? 0;
        if (retryCount >= _maxRetries) {
          if (_enableCircuitBreaker) _activateCircuitBreaker();
          return handler.next(error);
        }

        final delay = _calculateRetryDelay(retryCount);
        await Future.delayed(delay);

        error.requestOptions.extra['retryCount'] = retryCount + 1;

        try {
          final response = await _dio.request(
            error.requestOptions.path,
            data: error.requestOptions.data,
            options: Options(
              method: error.requestOptions.method,
              headers: error.requestOptions.headers,
              extra: error.requestOptions.extra,
            ),
          );
          return handler.resolve(response);
        } catch (_) {
          return handler.next(error);
        }
      },
    );
  }

  PrettyDioLogger _createLoggerInterceptor() {
    return PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
    );
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.response?.statusCode ?? 0) >= 500;
  }

  Duration _calculateRetryDelay(int retryCount) {
    final exponentialDelay = _retryDelay * (1 << retryCount);
    final jitter = Duration(milliseconds: (Random().nextDouble() * 1000).round());
    return exponentialDelay + jitter;
  }

  void _activateCircuitBreaker() {
    if (!_circuitOpen) {
      _circuitOpen = true;
      _lastFailureTime = DateTime.now();
      Timer(_circuitBreakerCooldown, _resetCircuitBreaker);
      if (kDebugMode) print('🛑 Circuit breaker activated!');
    }
  }

  void _resetCircuitBreaker() {
    if (_lastFailureTime != null &&
        DateTime.now().difference(_lastFailureTime!) >= _circuitBreakerCooldown) {
      _circuitOpen = false;
      if (kDebugMode) print('✅ Circuit breaker cooldown expired, back to normal.');
    }
  }

  Future<void> updateToken(String newToken) async {
    token = newToken;
    _dio.options.headers['Authorization'] = 'Bearer $newToken';
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _dio.close();
  }
}

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic> json) fromJsonT,
      ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}