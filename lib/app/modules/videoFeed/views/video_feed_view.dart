import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_demo1/app/widgets/custom_cupertino_switch.dart';
import 'package:getx_demo1/app/widgets/gradient_bound_painter.dart';
import 'package:getx_demo1/app/widgets/gradient_text.dart';
import 'package:getx_demo1/app/widgets/progress_bar.dart';

import '../controllers/video_feed_controller.dart';

final Random _random = Random();

Color randomColor() {
  return Color.fromARGB(
    128,
    _random.nextInt(256),
    _random.nextInt(256),
    _random.nextInt(256),
  );
}

class VideoFeedView extends GetView<VideoFeedController> {
  const VideoFeedView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VideoFeedView'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProgress(),
            _buildSwitch(),
            _buildGradientText(),
            _buildTags(),
          ],
        ),
      ),
    );
  }

  Widget _buildTags() {
    final tags = ['OC', 'BDSM', 'Teacher'];
    return Container(
      height: 40,
      color: randomColor(),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: tags.asMap().entries.map((entry) => _buildTag(text: entry.value)).toList(),
      ),
    );
  }

  Widget _buildTag({required String text}) {
    const textStyle = TextStyle(
      fontSize: 10,
      color: Colors.white,
      fontWeight: FontWeight.w300,
    );
    return Container(
      height: 14,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: LayoutBuilder(
        builder: (BuildContext _, BoxConstraints bc) {
          // 创建一个 TextPainter 来计算文本的宽度
          TextPainter textPainter = TextPainter(
            text: TextSpan(
              text: text,
              style: textStyle,
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          // 获取文本宽度
          double textWidth = textPainter.width;

          return CustomPaint(
            painter: GradientBoundPainter(
              colors: [
                const Color(0x4DFFDC39),
                const Color(0xFFFFDC39),
              ],
              strokeWidth: 1,
              width: textWidth + 12,
              height: bc.maxHeight,
            ),
            child: Text(text, style: textStyle),
          );
        },
      ),
    );
  }

  GradientText _buildGradientText() {
    return const GradientText(
      data: 'I Love Your',
      gradient: LinearGradient(colors: [
        Color(0xFFFF82AC),
        Color(0xFFFFEFA2),
      ]),
      style: TextStyle(
        fontSize: 50,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Container _buildSwitch() {
    return Container(
      height: 40,
      color: randomColor(),
      child: Row(
        children: [
          const Text('开关'),
          const SizedBox(width: 40),
          Obx(
            () => CustomCupertinoSwitch(
              value: controller.isOn.value,
              activeColor: const Color(0xFFFA538B),
              thumbColor: Colors.white,
              trackColor: const Color(0x80FFFFFF),
              onChanged: (value) {
                controller.isOn.value = value;
              },
            ),
          ),
        ],
      ),
    );
  }

  Container _buildProgress() {
    return Container(
      height: 40,
      color: randomColor(),
      child: Row(
        children: [
          const Text('进度条'),
          const SizedBox(width: 40),
          ProgressBar(
            duration: const Duration(seconds: 7),
            width: 200,
            height: 8,
            backgroundColor: Colors.grey,
            progressColor: Colors.white,
            borderRadius: 4,
            onProgress: (double value) {
              print('Current progress: $value');
            },
          ),
        ],
      ),
    );
  }
}
