import 'package:flutter/material.dart';

class OverLayerBall {
  static OverlayEntry? _holder;
  static late Widget view;

  static void remove() {
    _holder?.remove();
    _holder = null;
  }

  static void show({required BuildContext context, required Widget newView}) {
    view = newView;

    remove();

    final GlobalKey<_DraggableState> draggableKey = GlobalKey<_DraggableState>();

    final OverlayEntry overlayEntry = OverlayEntry(builder: (context) {
      return Positioned(
        top: MediaQuery.of(context).size.height * 0.7,
        child: _buildDraggable(draggableKey),
      );
    });

    Overlay.of(context).insert(overlayEntry);

    _holder = overlayEntry;
  }

  static Widget _buildDraggable(GlobalKey<_DraggableState> draggableKey) {
    return Draggable(
      key: draggableKey,
      feedback: view,
      onDragStarted: () {
        print('onDragStarted:');
      },
      onDragEnd: (detail) {
        print('onDragEnd:${detail.offset}');
        createDragTarget(offset: detail.offset, context: draggableKey.currentContext!);
      },
      childWhenDragging: Container(),
      child: view,
    );
  }

  static void refresh() {
    _holder?.markNeedsBuild();
  }

  static void createDragTarget({required Offset offset, required BuildContext context}) {
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
        left: isLeft ? 0 : null,
        right: isLeft ? null : 0,
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
            return _buildDraggable(context);
          },
        ),
      );
    });
    Overlay.of(context).insert(_holder!);
  }
}
