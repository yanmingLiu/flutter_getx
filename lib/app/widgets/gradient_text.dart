import 'package:flutter/material.dart';

class GradientText extends StatelessWidget {
  const GradientText({
    super.key,
    required this.data,
    required this.gradient,
    required this.style,
    this.textAlign = TextAlign.left,
  });

  final String data;
  final Gradient gradient;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          data,
          style: style.copyWith(color: Colors.transparent),
          textAlign: textAlign,
          strutStyle: StrutStyle.disabled,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) {
            return gradient.createShader(Offset.zero & bounds.size);
          },
          child: Text(
            data,
            style: style.copyWith(color: Colors.white),
            textAlign: textAlign,
            strutStyle: StrutStyle.disabled,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
        ),
      ],
    );
  }
}
