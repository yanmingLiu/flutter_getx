import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  const ExpandableText({
    super.key,
    required this.text,
    required this.maxLines,
    this.textStyle,
  });
  final String text;
  final int maxLines;
  final TextStyle? textStyle;

  @override
  ExpandableTextState createState() => ExpandableTextState();
}

class ExpandableTextState extends State<ExpandableText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final maxWidth = constraints.maxWidth;
        final textSpan = TextSpan(
          text: widget.text,
          style: widget.textStyle ?? const TextStyle(color: Colors.black),
        );

        final textPainter = TextPainter(
          text: textSpan,
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: maxWidth);

        if (!textPainter.didExceedMaxLines) {
          return Text(
            widget.text,
            textAlign: .center,
            style: widget.textStyle ?? const TextStyle(color: Colors.black),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            isExpanded
                ? _buildExpandedText()
                : _buildCollapsedText(textPainter, maxWidth),
          ],
        );
      },
    );
  }

  Widget _buildCollapsedText(TextPainter textPainter, double maxWidth) {
    final expandSpan = TextSpan(
      text: " More",
      style: const TextStyle(
        color: Color(0xFFFF8B85),
        fontSize: 10,
        fontWeight: .w700,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
    );

    final linkTextSpan = TextSpan(
      text: '...',
      style: widget.textStyle ?? const TextStyle(color: Colors.black),
      children: [expandSpan],
    );

    final linkPainter = TextPainter(
      text: linkTextSpan,
      textDirection: TextDirection.ltr,
    );
    linkPainter.layout(maxWidth: maxWidth);

    final position = textPainter.getPositionForOffset(
      Offset(maxWidth - linkPainter.width, textPainter.height),
    );
    final endOffset =
        textPainter.getOffsetBefore(position.offset) ?? position.offset;
    final truncatedText = widget.text.substring(0, endOffset);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: truncatedText,
        style: widget.textStyle ?? const TextStyle(color: Colors.black),
        children: [linkTextSpan],
      ),
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildExpandedText() {
    final collapseSpan = TextSpan(
      text: " Less",
      style: const TextStyle(
        color: Color(0xFFFF8B85),
        fontSize: 10,
        fontWeight: .w700,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: widget.text,
        style: widget.textStyle ?? const TextStyle(color: Colors.black),
        children: [collapseSpan],
      ),
    );
  }
}
