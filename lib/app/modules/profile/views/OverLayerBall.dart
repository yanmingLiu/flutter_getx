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
        top: MediaQuery.of(context).size.height * 0.7,
        child: Draggable(
          feedback: view,
          onDragStarted: () {
            print('onDragStarted:');
          },
          onDragEnd: (detail) {
            print('onDragEnd:${detail.offset}');
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

    _holder = OverlayEntry(builder: (context) {
      bool isLeft = true;
      if (offset.dx + 100 > MediaQuery.of(context).size.width / 2) {
        isLeft = false;
      }

      final double maxY = MediaQuery.of(context).size.height - 100;

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
            print('onWillAccept: $data');
            return true;
          },
          onAccept: (data) {
            print('onAccept: $data');
            // refresh();
          },
          onLeave: (data) {
            print('onLeave');
          },
          builder: (BuildContext context, List<dynamic> incoming, List<dynamic> rejected) {
            return Draggable(
              feedback: view,
              onDragStarted: () {
                print('onDragStarted:');
              },
              onDragEnd: (detail) {
                print('onDragEnd:${detail.offset}');
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
