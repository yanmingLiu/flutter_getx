import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

// 顶级变量，简化 log 使用
final log = LogService.log;

class LogService {
  static late File _logFile;

  // 创建一个全局的 Logger 实例
  static late Logger log;

  // 初始化 Logger
  static Future<void> initLogger() async {
    final directory = await getApplicationDocumentsDirectory();
    _logFile = File('${directory.path}/app_logs.txt');

    log = Logger(
      level: Level.debug,
      output: MultiOutput(
        [
          ConsoleOutput(), // 控制台输出
          FileOutput(file: _logFile), // 文件输出
        ],
      ),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
  }

  // 读取日志文件内容
  static Future<String> readLogFile() async {
    if (await _logFile.exists()) {
      return await _logFile.readAsString();
    } else {
      return "日志文件不存在";
    }
  }

  // 分享日志文件
  static void shareLogFile() {
    if (_logFile.existsSync()) {
      // Share.shareFiles([_logFile.path], text: '查看日志文件');
    } else {
      // 处理日志文件不存在的情况
    }
  }
}

class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key});

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  List<String> logLines = [];

  @override
  void initState() {
    super.initState();
    _loadLogFile();
  }

  Future<void> _loadLogFile() async {
    final content = await LogService.readLogFile();
    setState(() {
      // 将日志按行分割并保存到 logLines 列表中
      logLines = content.split('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志查看'),
        actions: const [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: LogService.shareLogFile,
          ),
        ],
      ),
      body: logLines.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: logLines.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: SelectableText(
                    logLines[index],
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontFamily: 'monospace', // 使用等宽字体显示日志
                    ),
                  ),
                );
              },
            ),
    );
  }
}
