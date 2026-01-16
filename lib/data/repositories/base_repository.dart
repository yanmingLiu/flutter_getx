import 'package:dio/dio.dart';

import '../../core/network/result.dart';
import '../../core/network/vortex.dart';

abstract class BaseRepository {
  /// 将 rawRequest 的响应安全转换为 Result<T>
  Future<VortexResult<T>> safeResult<T>(
    Future<Response<dynamic>> requestFuture,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final response = await requestFuture;
      final dynamic rawData = response.data;

      // 处理业务包装类格式
      if (rawData is Map<String, dynamic> && rawData.containsKey('code')) {
        final int code = rawData['code'];
        final String msg = rawData['msg'] ?? rawData['message'] ?? "Error";

        if (code == 200 || code == 0) {
          return Success(_mapData(rawData['data'], fromJson));
        }
        return Failure(ServerException(msg, code));
      }

      // 处理标准 RESTful
      return Success(_mapData(rawData, fromJson));
    } on VortexException catch (e) {
      // 捕获底层抛出的转译异常
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  T _mapData<T>(dynamic data, T Function(dynamic json) fromJson) {
    try {
      // 1. 处理 null 情况
      if (data == null) {
        if (T.toString().startsWith('List')) return [] as T;
        // 如果 T 是可空类型或有特殊业务需求，可在此扩展
        throw ParseException("Server returned null data");
      }

      // 2. 如果 data 已经是目标类型 T (例如 int, bool, String, Map, List)
      // 且不需要进一步转换，则直接返回
      if (data is T) {
        return data;
      }

      // 3. 处理列表类型
      if (data is List) {
        return data.map((e) => fromJson(e)).toList() as T;
      }

      // 4. 处理复杂对象转换
      return fromJson(data);
    } catch (e) {
      throw ParseException("Data mapping failed: $e");
    }
  }
}
