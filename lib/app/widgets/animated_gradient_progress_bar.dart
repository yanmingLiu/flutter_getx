import 'package:flutter/material.dart';

class AnimatedGradientProgressBar extends StatefulWidget {
  final double progress; // 当前进度，0.0 - 1.0
  final double width;
  final double height;
  final List<Color> gradientColors; // 渐变色列表
  final Color trackColor; // 轨道颜色
  final double borderRadius; // 圆角半径
  final Duration animationDuration; // 动画时长

  const AnimatedGradientProgressBar({
    Key? key,
    required this.progress,
    this.width = 250,
    this.height = 6,
    this.gradientColors = const [Color(0xFF53B4CC), Color(0xFFEBFF4C)], // 默认渐变色
    this.trackColor = const Color(0xFF2F330F), // 默认轨道颜色
    this.borderRadius = 3.0,
    this.animationDuration = const Duration(milliseconds: 300), // 默认动画时长
  })  : assert(progress >= 0.0 && progress <= 1.0, 'Progress must be between 0.0 and 1.0'),
        super(key: key);

  @override
  _AnimatedGradientProgressBarState createState() => _AnimatedGradientProgressBarState();
}

class _AnimatedGradientProgressBarState extends State<AnimatedGradientProgressBar> {
  late double _currentProgress;

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.progress; // 初始化当前进度
  }

  @override
  void didUpdateWidget(covariant AnimatedGradientProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      // 如果 progress 值发生变化，更新状态
      setState(() {
        _currentProgress = widget.progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.trackColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Stack(
        children: [
          // 使用 AnimatedContainer 为进度条添加动画
          AnimatedContainer(
            duration: widget.animationDuration,
            curve: Curves.easeInOut, // 使用平滑的动画曲线
            width: widget.width * _currentProgress, // 动态调整宽度
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        ],
      ),
    );
  }
}
