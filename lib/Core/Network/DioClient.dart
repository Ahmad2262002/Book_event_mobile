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

  // Base URL configuration
  static const String _localBaseUrl = 'http://localhost/alighaderfyp/api';
  static const String _networkBaseUrl = 'http://172.20.10.3:8000/api';
  bool _useLocalBaseUrl = false;

  DioClient({
    this.token,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    int? maxRetries,
    Duration? retryDelay,
    bool? enableCircuitBreaker,
    Duration? circuitBreakerCooldown,
    bool? useLocalBaseUrl,
  })  : _connectTimeout = connectTimeout ?? const Duration(seconds: 45),
        _receiveTimeout = receiveTimeout ?? const Duration(seconds: 45),
        _sendTimeout = sendTimeout ?? const Duration(seconds: 45),
        _maxRetries = maxRetries ?? 3,
        _retryDelay = retryDelay ?? const Duration(seconds: 2),
        _enableCircuitBreaker = enableCircuitBreaker ?? true,
        _circuitBreakerCooldown = circuitBreakerCooldown ?? const Duration(minutes: 1),
        _useLocalBaseUrl = useLocalBaseUrl ?? false {
    _initDio();
    _checkInitialConnectivity();
    _startConnectivityMonitoring();
  }

  String get baseUrl => _useLocalBaseUrl ? _localBaseUrl : _networkBaseUrl;

  void toggleBaseUrl(bool useLocal) {
    _useLocalBaseUrl = useLocal;
    _initDio(); // Reinitialize Dio with new base URL
  }

  Dio get instance => _dio;

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout: _sendTimeout,
        headers: _getDefaultHeaders(),
        persistentConnection: true,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Remove or modify the PrettyDioLogger configuration
    if (kDebugMode) {
      // Only show minimal logs in debug mode
      _dio.interceptors.add(PrettyDioLogger(
        requestHeader: false,  // Disable request headers
        requestBody: false,    // Disable request body
        responseBody: false,   // Disable response body
        error: false,          // Disable error logs
        compact: true,
      ));
    }

    // Keep other interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        // Your existing error handling
        if (error.type == DioExceptionType.connectionError &&
            baseUrl == _localBaseUrl) {
          toggleBaseUrl(false);
          try {
            final response = await _dio.request(
              error.requestOptions.path,
              data: error.requestOptions.data,
              options: Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              ),
            );
            return handler.resolve(response);
          } catch (e) {
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    ));

    _dio.interceptors.add(_createRetryInterceptor());
  }

  Future<void> autoDetectBaseUrl() async {
    try {
      // First try the network URL
      toggleBaseUrl(false);
      final testResponse = await _dio.get(
        '/test-connection',
        options: Options(
          headers: _getJsonHeaders(),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      if (testResponse.statusCode != 200) {
        throw Exception('Network URL failed');
      }
    } catch (e) {
      // If network fails, try local URL
      toggleBaseUrl(true);
      try {
        final testResponse = await _dio.get(
          '/test-connection',
          options: Options(
            headers: _getJsonHeaders(),
            receiveTimeout: const Duration(seconds: 3),
          ),
        );

        if (testResponse.statusCode != 200) {
          throw Exception('Both URLs failed');
        }
      } catch (e) {
        throw Exception('Could not connect to any API endpoint');
      }
    }
  }

  Map<String, String> _getDefaultHeaders() {
    return {
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip',
      'Connection': 'keep-alive',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> _getJsonHeaders() {
    return {
      ..._getDefaultHeaders(),
      'Content-Type': 'application/json',
    };
  }

  Map<String, String> _getMultipartHeaders() {
    return {
      ..._getDefaultHeaders(),
    };
  }

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
        options: Options(
          headers: {
            ..._getDefaultHeaders(),
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return _parseResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  ApiResponse<T> _parseResponse<T>(
      Response response,
      T Function(Map<String, dynamic> json) fromJsonT,
      ) {
    try {
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        // Special handling for stats endpoint
        if (response.requestOptions.path.contains('/admin/stats')) {
          final statsData = responseData['stats'] ?? responseData;
          return ApiResponse<T>(
            success: responseData['success'] ?? false,
            message: responseData['message'],
            data: fromJsonT(_convertStringNumbers(statsData)),
          );
        }

        // Handle all possible response formats
        if (responseData.containsKey('success')) {
          // First try to find data in known custom fields
          if (responseData.containsKey('events')) {
            return ApiResponse<T>(
              success: responseData['success'] ?? false,
              message: responseData['message'],
              data: fromJsonT({'events': responseData['events']}),
            );
          } else if (responseData.containsKey('bookings')) {
            return ApiResponse<T>(
              success: responseData['success'] ?? false,
              message: responseData['message'],
              data: fromJsonT({'bookings': responseData['bookings']}),
            );
          } else if (responseData.containsKey('users')) {
            return ApiResponse<T>(
              success: responseData['success'] ?? false,
              message: responseData['message'],
              data: fromJsonT({'users': responseData['users']}),
            );
          } else if (responseData.containsKey('testimonials')) {
            return ApiResponse<T>(
              success: responseData['success'] ?? false,
              message: responseData['message'],
              data: fromJsonT({'testimonials': responseData['testimonials']}),
            );
          }

          // Fall back to standard "data" field
          return ApiResponse<T>(
            success: responseData['success'] ?? false,
            message: responseData['message'],
            data: responseData['data'] != null
                ? fromJsonT(responseData['data'] ?? responseData)
                : null,
          );
        } else {
          // Direct data response
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

  Map<String, dynamic> _convertStringNumbers(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is String) {
        // Try to parse as int first
        final intValue = int.tryParse(value);
        if (intValue != null) return MapEntry(key, intValue);

        // Then try as double
        final doubleValue = double.tryParse(value);
        if (doubleValue != null) return MapEntry(key, doubleValue);
      }
      return MapEntry(key, value);
    });
  }

  ApiResponse<T> _handleError<T>(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      _activateCircuitBreaker();
    }

    if (e.response != null) {
      try {
        return ApiResponse<T>.fromJson(
          e.response?.data ?? {},
              (json) => null as T,
        );
      } catch (_) {
        return ApiResponse<T>(
          success: false,
          message: 'Request failed',
        );
      }
    } else {
      return ApiResponse<T>(
        success: false,
        message: 'Network error occurred',
      );
    }
  }

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