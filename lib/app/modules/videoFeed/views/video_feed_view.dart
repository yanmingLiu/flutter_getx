import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:getx_demo1/app/widgets/animated_gradient_progress_bar.dart';
import 'package:getx_demo1/app/widgets/custom_cupertino_switch.dart';
import 'package:getx_demo1/app/widgets/gradient_bound_painter.dart';
import 'package:getx_demo1/app/widgets/gradient_progress_bar.dart';
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
            _buildProgress2(),
            _buildProgress3(),
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
      color: randomColor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('渐变边框'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: tags.asMap().entries.map((entry) => _buildTag(text: entry.value)).toList(),
          ),
          const SizedBox(height: 16),
        ],
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

  Widget _buildGradientText() {
    return const Row(
      children: [
        Text('渐变文字'),
        GradientText(
          data: 'I Love You',
          gradient: LinearGradient(colors: [
            Color(0xFFFF82AC),
            Color(0xFFFFEFA2),
          ]),
          style: TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Container _buildSwitch() {
    return Container(
      height: 40,
      color: randomColor(),
      child: Row(
        children: [
          const Text('自定义开关'),
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
              // print('Current progress: $value');
              if (value == 1.0) {
                SmartDialog.showToast('加载完成');
              }
            },
          ),
        ],
      ),
    );
  }

  Container _buildProgress2() {
    return Container(
      height: 40,
      color: randomColor(),
      child: const Row(
        children: [
          Text('进度条'),
          SizedBox(width: 40),
          GradientProgressBar(
            progress: 0.5, // 设置进度百分比，0.0 - 1.0
            width: 300, // 宽度
            height: 8, // 高度
            gradientColors: [Color(0xFF53B4CC), Color(0xFFEBFF4C)], // 渐变色
            trackColor: Color(0xFF2F330F), // 轨道颜色
            borderRadius: 3, // 圆角
          ),
        ],
      ),
    );
  }

  Container _buildProgress3() {
    return Container(
      height: 40,
      color: randomColor(),
      child: Row(
        children: [
          const Text('进度条'),
          const SizedBox(width: 40),
          AnimatedGradientProgressBar(
            progress: controller.progress, // 当前进度
            width: 300,
            height: 8,
            gradientColors: const [Color(0xFF53B4CC), Color(0xFFEBFF4C)],
            trackColor: const Color(0xFF2F330F),
            borderRadius: 3,
            animationDuration: const Duration(milliseconds: 500), // 动画持续时间
          ),
        ],
      ),
    );
  }
}
