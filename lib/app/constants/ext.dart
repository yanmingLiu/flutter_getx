import 'dart:math';

import 'package:flutter/material.dart';

extension ColorExt on Color {
  /// 生成随机颜色，透明度固定为 0.5
  static Color random() {
    final Random random = Random();
    return Color.fromRGBO(
      random.nextInt(256), // 随机生成 R 值 (0-255)
      random.nextInt(256), // 随机生成 G 值 (0-255)
      random.nextInt(256), // 随机生成 B 值 (0-255)
      0.5, // 设置透明度为 0.5
    );
  }
}
