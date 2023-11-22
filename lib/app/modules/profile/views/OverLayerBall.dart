import 'package:flutter/material.dart';

class OverLayerBall {
  static OverlayEntry? _holder;
  static late Widget view;
  static bool isDismissed = false;

  static void remove() {
    _holder?.remove();
    _holder = null;
  }

  static void show({required BuildContext context, required Widget newView}) {
    view = newView;

    remove();

    final OverlayEntry overlayEntry = OverlayEntry(builder: (context) {
      return Positioned(
        bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 20,
        right: 20,
        child: Draggable(
          feedback: view,
          onDragStarted: () {
            debugPrint('onDragStarted:');
          },
          onDragEnd: (detail) {
            debugPrint('onDragEnd:${detail.offset}');
            createDragTarget(offset: detail.offset, context: context);
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

  static void createDragTarget({required Offset offset, required BuildContext context}) {
    if (isDismissed) return;

    _holder?.remove();

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    const double padding = 20.0;

    _holder = OverlayEntry(builder: (context) {
      bool isLeft = true;
      if (offset.dx > (screenWidth - padding * 2) / 2) {
        isLeft = false;
      }

      final double maxY = screenHeight -
          MediaQuery.of(context).padding.top -
          MediaQuery.of(context).padding.bottom -
          kBottomNavigationBarHeight -
          20;

      return Positioned(
        top: offset.dy < 50
            ? 50
            : offset.dy < maxY
                ? offset.dy
                : maxY,
        left: isLeft ? 20 : null,
        right: isLeft ? null : 20,
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
                createDragTarget(offset: detail.offset, context: context);
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
