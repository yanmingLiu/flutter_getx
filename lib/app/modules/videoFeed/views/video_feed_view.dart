import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_demo1/app/widgets/custom_cupertino_switch.dart';
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
          children: [
            Container(
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
            ),
            Container(
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
            ),
            const GradientText(
              data: 'I Love Your',
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
        ),
      ),
    );
  }
}
