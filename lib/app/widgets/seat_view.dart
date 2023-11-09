import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class Seat {
  int level = 0;
}

class Controller extends GetxController {
  var seats = <Seat>[];

  @override
  void onInit() {
    super.onInit();
    for (var i = 0; i < 8; i++) {
      final seat = Seat();
      seats.add(seat);
    }
    update();
  }

  void onPressed() {
    seats[2].level = 20;
    seats[5].level = 50;
    seats[0].level = 50;
    update();
  }
}

class RoomSeatCell extends StatefulWidget {
  const RoomSeatCell({
    Key? key,
    required this.seat,
    required this.width,
    required this.avatarSize,
  }) : super(key: key);

  final Seat seat;
  final double width;
  final double avatarSize;

  @override
  createState() => _RoomSeatCellState();
}

class _RoomSeatCellState extends State<RoomSeatCell> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isPlaying = false;
  bool _showLottie = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _showLottie = false;
          });
          _animationController.reset();
          _isPlaying = false;
        }
      });
    checkAndPlayAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RoomSeatCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    checkAndPlayAnimation();
  }

  void checkAndPlayAnimation() {
    if (widget.seat.level > 0) {
      if (!_isPlaying) {
        setState(() {
          _showLottie = true;
        });
        _animationController.forward();
        _isPlaying = true;
      }
    } else {
      setState(() {
        _showLottie = false;
      });
      _animationController.reset();
      _isPlaying = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: widget.width,
      height: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            color: Colors.green,
            width: widget.avatarSize,
            height: widget.avatarSize,
            child: widget.seat.level > 0
                ? OverflowBox(
                    maxWidth: widget.avatarSize * 2,
                    maxHeight: widget.avatarSize * 2,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_showLottie)
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Lottie.asset(
                                'assets/images/seat_ripple.json',
                                width: widget.avatarSize * 1.7,
                                height: widget.avatarSize * 1.7,
                                fit: BoxFit.fill,
                                controller: _animationController,
                                onLoaded: (composition) {
                                  _animationController.duration = composition.duration;
                                },
                              );
                            },
                          ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(widget.avatarSize / 2),
                          child: Container(
                            color: Colors.amber,
                            width: widget.avatarSize,
                            height: widget.avatarSize,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class SeatView extends StatelessWidget {
  final controller = Get.put(Controller());

  SeatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(onPressed: controller.onPressed, child: const Text('跟新动画')),
        GetBuilder<Controller>(
          builder: (_) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
              ),
              itemCount: controller.seats.length,
              itemBuilder: (BuildContext context, int index) {
                final seat = controller.seats[index];
                return RoomSeatCell(
                  seat: seat,
                  width: 60,
                  avatarSize: 52,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
