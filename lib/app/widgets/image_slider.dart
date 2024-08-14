import 'package:flutter/material.dart';

class ImageSlider extends StatefulWidget {
  const ImageSlider({Key? key}) : super(key: key);

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  double _sliderPosition = 0.5;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          // 返回 false 禁止返回操作
          return false;
        },
        child: Stack(
          children: [
            // 右侧图片
            Image.asset(
              'assets/images/undress.jpg', // 右侧图片路径
              width: screenWidth,
              height: screenHeight,
              fit: BoxFit.cover,
            ),
            // 左侧图片，根据_sliderPosition调整显示宽度
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: _sliderPosition, // 控制左侧图片显示的比例
                child: Image.asset(
                  'assets/images/original.jpg', // 左侧图片路径
                  width: screenWidth,
                  height: screenHeight,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // 滑块
            Positioned(
              left: screenWidth * _sliderPosition - 25,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _sliderPosition += details.delta.dx / screenWidth;
                    _sliderPosition = _sliderPosition.clamp(0.0, 1.0);
                  });
                },
                child: Container(
                  width: 50,
                  color: Colors.transparent,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 1.5,
                        color: Colors.grey,
                      ),
                      const Center(
                        child: Icon(Icons.drag_indicator, color: Colors.white, size: 50),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
