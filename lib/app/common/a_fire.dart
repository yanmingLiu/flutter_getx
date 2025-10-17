import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:logger/logger.dart';

enum AFireMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  head('HEAD'),
  options('OPTIONS'),
  patch('PATCH');

  // 声明构造函数
  const AFireMethod(this.value);

  // 定义存储参数的属性
  final String value;
}

/// Dio utility class
class AFire {
  static final AFire _instance = AFire._internal();
  factory AFire() => _instance;
  AFire._internal();

  late Dio _dio;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );
  final Connectivity _connectivity = Connectivity();

  // Direct storage properties
  String _token = '';
  String _proxy = '';

  // Basic configuration
  static const String _baseUrl = 'https://api.example.com';
  static const int _connectTimeout = 15000;
  static const int _receiveTimeout = 15000;
  static const int _sendTimeout = 10000;

  // 初始化Dio实例
  void init({
    String? baseUrl,
    Map<String, String>? headers,
    bool enableLog = true,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? _baseUrl,
        connectTimeout: const Duration(milliseconds: _connectTimeout),
        receiveTimeout: const Duration(milliseconds: _receiveTimeout),
        sendTimeout: const Duration(milliseconds: _sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?headers,
        },
      ),
    );

    // Add interceptors
    _addInterceptors(enableLog);

    // Configure proxy (if needed)
    _setupProxy();

    _logger.i('Dio initialization completed');
  }

  // Get Dio instance
  Dio get dio => _dio;

  // Add interceptors
  void _addInterceptors(bool enableLog) {
    // Request interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Check network connection
          final connectivityResult = await _connectivity.checkConnectivity();
          if (connectivityResult.contains(ConnectivityResult.none)) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'Network connection unavailable',
                type: DioExceptionType.unknown,
              ),
            );
            return;
          }

          // Add authentication token (if available)
          if (_token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }

          // Add request ID for tracking
          options.headers['X-Request-ID'] = _generateRequestId();

          if (enableLog) {
            _logger.d(
                'Request sent: ${options.method} ${options.baseUrl} ${options.path}\nRequest headers: ${options.headers}\nRequest body: ${options.data}');
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (enableLog) {
            _logger.d(
                'Response received: ${response.statusCode} ${response.requestOptions.path}\nResponse body: ${response.data}');
          }

          handler.next(response);
        },
        onError: (error, handler) {
          _handleError(error);
          handler.next(error);
        },
      ),
    );

    // Custom retry interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final extra = error.requestOptions.extra;
          final retryCount = extra['retryCount'] ?? 0;

          // Get the maximum retry count specified in the request, or use default value 3
          final maxRetryCount = extra['maxRetryCount'] ?? 0;

          // Retry if it's a network error or server error and retry count is less than the maximum
          if ((error.type == DioExceptionType.connectionError ||
                  error.type == DioExceptionType.receiveTimeout ||
                  error.type == DioExceptionType.sendTimeout ||
                  (error.type == DioExceptionType.badResponse &&
                      (error.response?.statusCode ?? 0) >= 500)) &&
              retryCount < maxRetryCount) {
            extra['retryCount'] = retryCount + 1;
            _logger.d(
                'Retrying request: ${error.requestOptions.path}, retry count: ${extra['retryCount']}/$maxRetryCount');

            try {
              await Future.delayed(const Duration(seconds: 1));
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
            } catch (e) {
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  // Setup proxy (if needed)
  void _setupProxy() {
    if (_proxy.isNotEmpty) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.findProxy = (uri) {
          return 'PROXY $_proxy';
        };
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
  }

  // Error handling
  void _handleError(DioException error) {
    String errorMessage = 'Unknown error';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = 'Connection timeout';
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = 'Request timeout';
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Response timeout';
        break;
      case DioExceptionType.badResponse:
        errorMessage = _handleHttpError(error.response?.statusCode ?? 0);
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'Network connection error';
        break;
      case DioExceptionType.badCertificate:
        errorMessage = 'Certificate verification failed';
        break;
      case DioExceptionType.unknown:
        errorMessage = error.error?.toString() ?? 'Unknown error';
        break;
    }

    _logger.e('Request error: $errorMessage');
    _logger.e('Error details: ${error.toString()}');

    // You can add global error handling logic here, such as displaying error messages
    SmartDialog.showToast(errorMessage, displayType: SmartToastType.onlyRefresh);
  }

  // Handle HTTP errors
  String _handleHttpError(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized, please login again';
      case 403:
        return 'Access denied';
      case 404:
        return 'Resource not found';
      case 405:
        return 'Method not allowed';
      case 408:
        return 'Request timeout';
      case 500:
        return 'Internal server error';
      case 502:
        return 'Gateway error';
      case 503:
        return 'Service unavailable';
      case 504:
        return 'Gateway timeout';
      default:
        return 'HTTP error: $statusCode';
    }
  }

  // Generate request ID
  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // 通用请求方法
  Future<Response<T>> request<T>(
    String path, {
    required AFireMethod method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final requestOptions = options ?? Options();

      return await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions.copyWith(method: method.value),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _logger.e('$method request failed: $path', error: e);
      rethrow;
    }
  }

  // File upload
  Future<Response> uploadFile(
    String path,
    File file, {
    String? fieldName,
    ProgressCallback? onSendProgress,
    Map<String, String>? fields,
    int? maxRetryCount,
    CancelToken? cancelToken,
  }) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        fieldName ?? 'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        ...?fields,
      });

      final options = Options();
      options.extra = {};

      // Set retry count (if provided)
      if (maxRetryCount != null) {
        options.extra!['maxRetryCount'] = maxRetryCount;
      }

      return await request(
        path,
        method: AFireMethod.post,
        data: formData,
        options: options,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    } catch (e) {
      _logger.e('File upload failed: $path', error: e);
      rethrow;
    }
  }

  // File download
  Future<Response> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Options? options,
    int? maxRetryCount,
    CancelToken? cancelToken,
  }) async {
    try {
      final requestOptions = options ?? Options();
      requestOptions.extra ??= {};

      // Set retry count (if provided)
      if (maxRetryCount != null) {
        requestOptions.extra!['maxRetryCount'] = maxRetryCount;
      }

      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: requestOptions,
        cancelToken: cancelToken,
      );
    } catch (e) {
      _logger.e('File download failed: $urlPath', error: e);
      rethrow;
    }
  }

  // Set proxy
  void setProxy(String proxy) {
    _proxy = proxy;
    _setupProxy();
    _logger.i('Proxy set: $proxy');
  }

  // Clear proxy
  void clearProxy() {
    _proxy = '';
    _setupProxy();
    _logger.i('Proxy cleared');
  }

  // Set authentication token
  void setAuthToken(String token) {
    _token = token;
    _logger.i('Authentication token set');
  }

  // Clear authentication token
  void clearAuthToken() {
    _token = '';
    _logger.i('Authentication token cleared');
  }
}
