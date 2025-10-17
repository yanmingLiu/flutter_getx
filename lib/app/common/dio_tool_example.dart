import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'a_fire.dart';

class DioToolExamplePage extends StatefulWidget {
  const DioToolExamplePage({super.key});

  @override
  State<DioToolExamplePage> createState() => _DioToolExamplePageState();
}

class _DioToolExamplePageState extends State<DioToolExamplePage> {
  @override
  void initState() {
    super.initState();
    DioToolExample.initDio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DioTool Example'),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => DioToolExample.getExample(),
              child: const Text('GET请求示例'),
            ),
            ElevatedButton(
              onPressed: () => DioToolExample.postExample(),
              child: const Text('POST请求示例'),
            ),
            ElevatedButton(
              onPressed: () => DioToolExample.downloadExample(),
              child: const Text('下载'),
            ),
          ],
        ),
      ),
    );
  }
}

/// DioTool使用示例
class DioToolExample {
  // 单例访问
  static final AFire _dioTool = AFire();

  /// 初始化Dio工具类
  /// 通常在应用启动时调用
  static void initDio() {
    _dioTool.init(
      baseUrl: 'https://liuhaipeng3.powerfulclean.net', // 示例API
      headers: {
        'device-id': 'fast-android.1ffcc708a5b57a3c',
        'platform': 'fast-android',
      },
      enableLog: kDebugMode, // 仅在调试模式下启用日志
    );
  }

  /// GET请求示例
  static Future<void> getExample() async {
    try {
      // 简单GET请求
      final response = await _dioTool.request(
        '/v2/appUser/getByDeviceId',
        method: AFireMethod.get,
        queryParameters: {
          'device_id': 'fast-android.1ffcc708a5b57a3c',
        },
      );
      bool isFromCache = response.extra.containsKey('isCache') && response.extra['isCache'] == true;
      debugPrint('是否从缓存获取: $isFromCache');
    } catch (e) {
      debugPrint('GET请求失败: $e');
    }
  }

  /// POST请求示例
  static Future<void> postExample() async {
    try {
      final response = await _dioTool.request(
        '/v2/characterProfile/getAll',
        method: AFireMethod.post,
        queryParameters: {'v': 'C001'},
        data: {"page": 1, "size": 10, "platform": "Kira"},
      );

      debugPrint('创建的文章: ${response.data}');
    } catch (e) {
      debugPrint('POST请求失败: $e');
    }
  }

  /// 文件上传示例
  static Future<void> uploadExample() async {
    try {
      // 创建一个临时文件用于演示
      final file = File('/path/to/your/file.jpg'); // 替换为实际文件路径

      if (await file.exists()) {
        final response = await _dioTool.uploadFile(
          '/upload', // 替换为实际的上传接口
          file,
          fieldName: 'file',
          onSendProgress: (sent, total) {
            debugPrint('上传进度: ${(sent / total * 100).toStringAsFixed(0)}%');
          },
        );

        debugPrint('上传结果: ${response.data}');
      } else {
        debugPrint('文件不存在');
      }
    } catch (e) {
      debugPrint('文件上传失败: $e');
    }
  }

  /// 文件下载示例
  static Future<void> downloadExample() async {
    try {
      // 下载示例图片
      const imageUrl = 'https://haowallpaper.com/link/common/file/previewFileImg/17469703159139712';
      final savePath = '${Directory.systemTemp.path}/17469703159139712.mp4';

      final response = await _dioTool.downloadFile(
        imageUrl,
        savePath,
        onReceiveProgress: (received, total) {
          debugPrint('下载进度: ${(received / total * 100).toStringAsFixed(0)}%');
        },
      );

      debugPrint('下载完成: ${response.statusCode}');
      debugPrint('保存路径: $savePath');
    } catch (e) {
      debugPrint('文件下载失败: $e');
    }
  }

  /// 设置认证token示例
  static void setAuthExample() {
    // 设置认证token
    _dioTool.setAuthToken('your_token_here');

    // 现在所有请求都会包含Authorization头
    debugPrint('认证token已设置');
  }

  /// 清除认证token示例
  static void clearAuthExample() {
    // 清除认证token
    _dioTool.clearAuthToken();

    debugPrint('认证token已清除');
  }

  /// 设置代理示例
  static void setProxyExample() {
    // 设置代理
    _dioTool.setProxy('192.168.1.100:8888');

    debugPrint('代理已设置');
  }

  /// 清除代理示例
  static void clearProxyExample() {
    // 清除代理
    _dioTool.clearProxy();

    debugPrint('代理已清除');
  }
}
