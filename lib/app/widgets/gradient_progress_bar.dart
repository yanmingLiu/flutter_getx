import 'package:flutter/material.dart';

class GradientProgressBar extends StatelessWidget {
  final double progress; // 当前进度，0.0 - 1.0
  final double width;
  final double height;
  final List<Color> gradientColors; // 渐变色列表
  final Color trackColor; // 轨道颜色
  final double borderRadius; // 圆角半径

  const GradientProgressBar({
    Key? key,
    required this.progress,
    this.width = 250,
    this.height = 6,
    this.gradientColors = const [Color(0xFF53B4CC), Color(0xFFEBFF4C)], // 默认渐变色
    this.trackColor = const Color(0xFF2F330F), // 默认轨道颜色
    this.borderRadius = 3.0,
  })  : assert(progress >= 0.0 && progress <= 1.0, 'Progress must be between 0.0 and 1.0'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Stack(
        children: [
          // 渐变色进度条
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress, // 根据进度调整宽度
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
