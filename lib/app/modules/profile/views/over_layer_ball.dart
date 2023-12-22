import 'package:flutter/material.dart';

class OverLayerBall {
  static OverlayEntry? _holder;
  static late Widget view;
  static bool isDismissed = false;

  static void remove() {
    _holder?.remove();
    _holder = null;
  }

  static void show({
    required BuildContext context,
    required Widget child,
    required double horizontalMargin,
    required double bottomMargin,
  }) {
    view = child;

    remove();

    final OverlayEntry overlayEntry = OverlayEntry(builder: (context) {
      return Positioned(
        bottom: bottomMargin,
        right: horizontalMargin,
        child: Draggable(
          feedback: view,
          onDragStarted: () {
            debugPrint('onDragStarted:');
          },
          onDragEnd: (detail) {
            debugPrint('onDragEnd:${detail.offset}');
            createDragTarget(
              offset: detail.offset,
              context: context,
              horizontalMargin: horizontalMargin,
              bottomMargin: bottomMargin,
            );
          },
          childWhenDragging: Container(),
          child: view,
        ),
      );
    });

    Overlay.of(context).insert(overlayEntry);

    _holder = overlayEntry;
  }

  static void refresh() {
    _holder?.markNeedsBuild();
  }

  static void dismiss() {
    isDismissed = true;
    remove();
  }

  static void createDragTarget({
    required Offset offset,
    required BuildContext context,
    required double horizontalMargin,
    required double bottomMargin,
  }) {
    if (isDismissed) return;

    _holder?.remove();

    _holder = OverlayEntry(builder: (context) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final double screenHeight = MediaQuery.of(context).size.height;
      final double maxWidth = screenWidth - horizontalMargin * 2;

      final double maxY = screenHeight -
          MediaQuery.of(context).padding.top //
          -
          kBottomNavigationBarHeight //
          -
          bottomMargin; //

      const double top = 50.0;

      bool isLeft = true;
      if (offset.dx > maxWidth / 2) {
        isLeft = false;
      }

      return Positioned(
        top: offset.dy < top
            ? top
            : offset.dy < maxY
                ? offset.dy
                : maxY,
        left: isLeft ? horizontalMargin : null,
        right: isLeft ? null : horizontalMargin,
        child: DragTarget(
          onWillAccept: (data) {
            debugPrint('onWillAccept: $data');
            return true;
          },
          onAccept: (data) {
            debugPrint('onAccept: $data');
            // refresh();
          },
          onLeave: (data) {
            debugPrint('onLeave');
          },
          builder: (BuildContext context, List<dynamic> incoming, List<dynamic> rejected) {
            return Draggable(
              feedback: view,
              onDragStarted: () {
                debugPrint('onDragStarted:');
              },
              onDragEnd: (detail) {
                debugPrint('onDragEnd:${detail.offset}');
                createDragTarget(
                  offset: detail.offset,
                  context: context,
                  horizontalMargin: horizontalMargin,
                  bottomMargin: bottomMargin,
                );
              },
              childWhenDragging: Container(),
              child: view,
            );
          },
        ),
      );
    });
    Overlay.of(context).insert(_holder!);
  }
}

class RotatingContainer extends StatefulWidget {
  const RotatingContainer({super.key, required this.child});

  final Widget child;

  @override
  State<RotatingContainer> createState() => _RotatingContainerState();
}

class _RotatingContainerState extends State<RotatingContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(turns: _controller, child: widget.child);
  }
}
