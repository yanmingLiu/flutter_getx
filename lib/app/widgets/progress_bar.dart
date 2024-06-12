import 'package:flutter/material.dart';

class ProgressBar extends StatefulWidget {
  final Duration duration;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color progressColor;
  final double borderRadius;
  final Function(double) onProgress;

  const ProgressBar({
    super.key,
    required this.duration,
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.progressColor,
    required this.borderRadius,
    required this.onProgress,
  });

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )
      ..addListener(() {
        widget.onProgress(_controller.value);
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _controller.value,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.progressColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
