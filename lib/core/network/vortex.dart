import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'cipher.dart';

abstract class HttpMethod {
  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String delete = 'DELETE';
  static const String patch = 'PATCH';
}

/*
 \ \    / /       | |           
  \ \  / /__  _ __| |_ _____  __
   \ \/ / _ \| '__| __/ _ \ \/ /
    \  / (_) | |  | ||  __/>  < 
     \/ \___/|_|   \__\___/_/\_\
*/
class Vortex {
  static final Vortex instance = Vortex._internal();
  Vortex._internal();

  Dio? _dioInstance;
  bool _isCrypto = false;

  Dio get _dio {
    if (_dioInstance == null) setup(); // 默认配置自启动
    return _dioInstance!;
  }

  void setup({
    String? baseUrl,
    Map<String, dynamic>? headers,
    bool isCrypto = false,
  }) {
    _isCrypto = isCrypto;
    _dioInstance = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: const Duration(seconds: 30),
        // 全局 responseType：加密则用 plain，不加密则用 json
        responseType: isCrypto ? ResponseType.plain : ResponseType.json,
        headers: {'Content-Type': 'application/json', ...?headers},
      ),
    );

    _dioInstance!.interceptors.addAll([
      if (_isCrypto) _CrypptoInterceptor(),
      _ErrorInterceptor(), // 负责将 DioException 转为 VortexException
      if (kDebugMode && !_isCrypto) LogInterceptor(responseBody: true),
    ]);
  }

  /// 底层安全请求：屏蔽 Dio 原始异常
  /// 返回 让 Repository 去处理具体解析
  Future<Response<T>> rawRequest<T>(
    String path, {
    String method = HttpMethod.get,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options?.copyWith(method: method) ?? Options(method: method),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      // 使用 as Object 确保非空，或者直接强转为 VortexException
      throw (e.error is VortexException)
          ? e.error as VortexException
          : UnknownException(e.message ?? "Unknown Error", null, e);
    } catch (e) {
      // 兜底非 Dio 异常
      throw UnknownException(e.toString());
    }
  }

  Future<Response> uploadFile(
    String path, {
    required FormData data,
    Options? options,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) => _dio.post(
    path,
    data: data,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
  );

  Future<Response> downloadFile(
    String urlPath,
    String savePath, {
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) => _dio.download(
    urlPath,
    savePath,
    options: options,
    cancelToken: cancelToken,
    onReceiveProgress: onReceiveProgress,
  );
}

/*
  _____       _                          _             
 |_   _|     | |                        | |            
   | |  _ __ | |_ ___ _ __ ___ ___ _ __ | |_ ___  _ __ 
   | | | '_ \| __/ _ \ '__/ __/ _ \ '_ \| __/ _ \| '__|
  _| |_| | | | ||  __/ | | (_|  __/ |_) | || (_) | |   
 |_____|_| |_|\__\___|_|  \___\___| .__/ \__\___/|_|   
                                  | |                  
                                  |_|        
*/
class _CrypptoInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      final encryptedUrl = Cipher.encryptUrl(
        originalUrl: options.uri.toString(),
      );
      final newUri = Uri.parse(encryptedUrl);
      options.path = newUri.path;

      if (options.contentType != 'multipart/form-data') {
        options.data = Cipher.encryptParams(options.data);
      }

      super.onRequest(options, handler);
    } catch (e) {
      handler.reject(
        DioException(requestOptions: options, message: "Encrypt Error: $e"),
      );
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    try {
      final decrypted = Cipher.decrypt(response.data);
      if (decrypted.length < 10240) {
        response.data = json.decode(decrypted);
      } else {
        response.data = await compute(json.decode, decrypted);
      }
      super.onResponse(response, handler);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          error: e,
          message: "Decrypt Error: $e",
        ),
      );
    }
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = _parseError(err);

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        error: appException,
        type: err.type,
        response: err.response,
        stackTrace: err.stackTrace,
      ),
    );
  }

  /// 将 DioException 转换为 AppException
  VortexException _parseError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(_getTimeoutMessage(error.type), null, error);

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode != null) {
          // 401/403 认证错误
          if (statusCode == 401 || statusCode == 403) {
            return AuthException('Unauthorized', statusCode, error);
          }
          // 其他服务器错误
          return ServerException(
            _getHttpErrorMessage(statusCode),
            statusCode,
            error,
          );
        }
        return ServerException('Server error', null, error);

      case DioExceptionType.cancel:
        return CancelException('Request cancelled', null, error);

      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return NetworkException(
          _getNetworkErrorMessage(error.type),
          null,
          error,
        );

      case DioExceptionType.unknown:
        // 检查是否是网络连接错误
        if (error.error.toString().contains('SocketException') ||
            error.error.toString().contains('Failed host lookup')) {
          return NetworkException('Network connection failed', null, error);
        }
        return UnknownException(
          error.error?.toString() ?? 'Unknown error',
          null,
          error,
        );
    }
  }

  String _getTimeoutMessage(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Request send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout';
      default:
        return 'Request timeout';
    }
  }

  String _getNetworkErrorMessage(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionError:
        return 'Network connection failed';
      case DioExceptionType.badCertificate:
        return 'Certificate verification failed';
      default:
        return 'Network error';
    }
  }

  String _getHttpErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Access denied';
      case 404:
        return 'Not found';
      case 405:
        return 'Method not allowed';
      case 408:
        return 'Request timeout';
      case 500:
        return 'Server error';
      case 502:
        return 'Gateway error';
      case 503:
        return 'Service unavailable';
      case 504:
        return 'Gateway timeout';
      default:
        return 'Server error: $statusCode';
    }
  }
}

/*
   ______                    _   _             
 |  ____|                  | | (_)            
 | |__  __  _____ ___ _ __ | |_ _  ___  _ __  
 |  __| \ \/ / __/ _ \ '_ \| __| |/ _ \| '_ \ 
 | |____ >  < (_|  __/ |_) | |_| | (_) | | | |
 |______/_/\_\___\___| .__/ \__|_|\___/|_| |_|
                     | |                      
                     |_|             
*/
abstract class VortexException implements Exception {
  final String message;
  final int? code;
  final dynamic originalError;

  VortexException(this.message, [this.code, this.originalError]);

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// 网络连接异常
class NetworkException extends VortexException {
  NetworkException(super.message, [super.code, super.originalError]);

  @override
  String toString() => 'NetworkException: $message (code: $code)';
}

/// 超时异常
class TimeoutException extends VortexException {
  TimeoutException(super.message, [super.code, super.originalError]);

  @override
  String toString() => 'TimeoutException: $message';
}

/// 服务器异常
class ServerException extends VortexException {
  ServerException(super.message, [super.code, super.originalError]);

  @override
  String toString() => 'ServerException: $message (code: $code)';
}

/// 认证异常
class AuthException extends VortexException {
  AuthException(super.message, [super.code, super.originalError]);

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// 解析异常
class ParseException extends VortexException {
  ParseException(super.message, [super.code, super.originalError]);

  @override
  String toString() => 'ParseException: $message';
}

/// 取消请求异常
class CancelException extends VortexException {
  CancelException(super.message, [super.code, super.originalError]);

  @override
  String toString() => 'CancelException: $message';
}

/// 未知异常
class UnknownException extends VortexException {
  UnknownException(super.message, [super.code, super.originalError]);

  @override
  String toString() => 'UnknownException: $message';
}
