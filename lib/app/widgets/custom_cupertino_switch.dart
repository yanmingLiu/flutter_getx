import 'package:flutter/material.dart';

class CustomCupertinoSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;
  final Color thumbColor;
  final Color trackColor;

  const CustomCupertinoSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor = const Color(0xFFFA538B),
    this.thumbColor = Colors.white,
    this.trackColor = Colors.white,
  });

  @override
  State<CustomCupertinoSwitch> createState() => _CustomCupertinoSwitchState();
}

class _CustomCupertinoSwitchState extends State<CustomCupertinoSwitch> {
  @override
  Widget build(BuildContext context) {
    bool value = widget.value; // 直接使用传入的 value 控制外观

    return GestureDetector(
      onTap: () {
        setState(() {
          value = !value;
          if (widget.onChanged != null) {
            widget.onChanged!(value);
          }
        });
      },
      child: Container(
        width: 56,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? widget.activeColor : widget.trackColor,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: value ? 28 : 2,
              right: value ? 2 : 28,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.thumbColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
