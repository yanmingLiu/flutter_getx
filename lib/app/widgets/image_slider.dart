import 'package:flutter/material.dart';

class ImageSlider extends StatefulWidget {
  const ImageSlider({super.key});

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _sliderPosition = 0.5;
  final pointerSize = 50.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {
          _sliderPosition = _animation.value;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // 动画完成后创建新的动画从 1.0 返回到 0.5
          _controller.duration = const Duration(seconds: 1);
          _animation = Tween<double>(begin: 1.0, end: 0.5).animate(_controller)
            ..addListener(() {
              setState(() {
                _sliderPosition = _animation.value;
              });
            })
            ..addStatusListener((status) {
              if (status == AnimationStatus.completed) {
                // 停止动画
                _controller.reset();
                _sliderPosition = 0.5;
              }
            });

          _controller.reset();
          _controller.forward();
        }
      });

    // 开始动画
    _controller.forward();
  }

  @override
  void dispose() {
    // 确保在小部件销毁时释放资源
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;

      return Stack(
        children: [
          // 右侧图片
          Image.asset(
            'assets/images/original.jpg', // 左侧图片路径
            width: width,
            height: height,
            fit: BoxFit.cover,
          ),
          // 左侧图片，根据_sliderPosition调整显示宽度
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: _sliderPosition, // 控制左侧图片显示的比例
              child: Image.asset(
                'assets/images/undress.jpg', // 右侧图片路径
                width: width,
                height: height,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 滑块
          Positioned(
            left: width * _sliderPosition - pointerSize / 2, // 支持负数的left值
            top: 0,
            bottom: 0,
            child: Container(
              color: Colors.transparent,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onPanUpdate: (details) {
                      // 禁止动画过程中手势操作
                      if (!_controller.isAnimating) {
                        setState(() {
                          _sliderPosition += details.delta.dx / width;
                          _sliderPosition = _sliderPosition.clamp(0.0, 1.0);
                        });
                      }
                    },
                    child: Container(
                      width: pointerSize,
                      height: pointerSize,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.0),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Icon(Icons.arrow_left, size: 20.0, color: Colors.white),
                          Icon(Icons.arrow_right, size: 20.0, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}
