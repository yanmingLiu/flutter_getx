import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/video_feed_controller.dart';

class VideoFeedView extends GetView<VideoFeedController> {
  const VideoFeedView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VideoFeedView'),
      ),
      body: GiftPage(),
    );
  }
}

// class Gift {
//   final String id;
//   int num;

//   Gift(this.id, this.num);
// }

// // StatefulWidget实现
// class GiftAnimation extends StatefulWidget {
//   final Gift gift;
//   final VoidCallback onAnimationComplete;

//   const GiftAnimation({
//     Key? key,
//     required this.gift,
//     required this.onAnimationComplete,
//   }) : super(key: key);

//   @override
//   createState() => _GiftAnimationState();
// }

// class _GiftAnimationState extends State<GiftAnimation> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<Offset> _animation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     );

//     _animation = Tween<Offset>(
//       begin: const Offset(-1, 0),
//       end: const Offset(0.1, 0),
//     ).animate(CurvedAnimation(
//       parent: _controller,
//       curve: Curves.fastOutSlowIn,
//     ));

//     _controller.forward().then((_) {
//       Future.delayed(const Duration(seconds: 2), () {
//         if (mounted) {
//           _controller.reverse().then((_) {
//             if (mounted) {
//               widget.onAnimationComplete();
//               print('GiftAnimation finished');
//             }
//           });
//         }
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SlideTransition(
//       position: _animation,
//       child: Container(
//         width: 100,
//         height: 100,
//         decoration: BoxDecoration(
//           color: Colors.red,
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Center(
//           child: Text('Gift Animation for ${widget.gift.id}'),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }

// class GiftPage extends StatefulWidget {
//   const GiftPage({super.key});

//   @override
//   _GiftPageState createState() => _GiftPageState();
// }

// class _GiftPageState extends State<GiftPage> {
//   final List<Gift> _queue = [];
//   bool _isAnimating = false;

//   void addGift(Gift gift) {
//     final existingGift = _queue.firstWhere((g) => g.id == gift.id, orElse: () => Gift('', 0));
//     if (existingGift.id.isNotEmpty) {
//       existingGift.num += gift.num;
//     } else {
//       _queue.add(gift);
//       if (!_isAnimating) {
//         _playNextAnimation();
//       }
//     }
//   }

//   void _playNextAnimation() async {
//     if (_queue.isNotEmpty) {
//       final currentGift = _queue.removeAt(0);
//       _isAnimating = true;

//       onAnimationComplete() {
//         _isAnimating = false;
//         _playNextAnimation();
//       }

//       final animation = GiftAnimation(
//         key: ValueKey(currentGift.id),
//         gift: currentGift,
//         onAnimationComplete: onAnimationComplete,
//       );

//       setState(() {
//         _isAnimating = true;
//         _currentAnimation = animation;
//       });

//       await Future.delayed(const Duration(milliseconds: 2500)); // Animation duration + 500ms delay

//       if (mounted) {
//         setState(() {
//           _currentAnimation = null;
//         });
//       }

//       _playNextAnimation();
//     }
//   }

//   Widget? _currentAnimation;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Gift Page'),
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           ElevatedButton(
//             onPressed: () {
//               final id = Random().nextInt(100000);
//               addGift(Gift('$id', 1));
//             },
//             child: const Text('Send Gift'),
//           ),
//           const SizedBox(height: 20),
//           if (_currentAnimation != null) _currentAnimation!,
//         ],
//       ),
//     );
//   }
// }

/// GetxController 单个动画控制

// class GiftController extends GetxController {
//   final _queue = <Gift>[].obs;
//   final _isAnimating = false.obs;

//   List<Gift> get queue => _queue.toList();
//   bool get isAnimating => _isAnimating.value;

//   void addGift(Gift gift) {
//     final existingGift = _queue.firstWhere((g) => g.id == gift.id, orElse: () => Gift('', 0));
//     if (existingGift.id.isNotEmpty) {
//       existingGift.num += gift.num;
//     } else {
//       _queue.add(gift);
//       print('addGift : ${gift.id} - $_queue');
//       if (!isAnimating) {
//         _playNextAnimation();
//       }
//     }
//   }

//   void _playNextAnimation() async {
//     if (_queue.isNotEmpty) {
//       final currentGift = _queue[0]; // Get the first gift without removing it
//       _isAnimating.value = true;

//       await Future.delayed(const Duration(milliseconds: 1500)); // Optional delay

//       _queue.removeAt(0); // Remove the gift after the animation

//       _isAnimating.value = false;
//       _playNextAnimation();
//     }
//   }
// }

// class GiftPage extends StatelessWidget {
//   final GiftController _giftController = Get.put(GiftController());

//   GiftPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Gift Page'),
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           ElevatedButton(
//             onPressed: () {
//               final id = Random().nextInt(100000);
//               _giftController.addGift(Gift('$id', 1));
//             },
//             child: const Text('Send Gift'),
//           ),
//           const SizedBox(height: 20),
//           Obx(() {
//             final currentAnimation = _giftController.queue.isNotEmpty
//                 ? GiftAnimation(
//                     key: ValueKey(_giftController.queue.first.id),
//                     gift: _giftController.queue.first,
//                     onAnimationComplete: _giftController._playNextAnimation,
//                   )
//                 : const SizedBox(); // Or any other widget if no animation is playing
//             return currentAnimation;
//           }),
//         ],
//       ),
//     );
//   }
// }

/// 2个动画控制
///
extension SafeList<T> on List<T> {
  T? safeGet(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }
}

class Gift {
  final String id;
  int num;

  Gift(this.id, this.num);
}

class GiftPage extends StatelessWidget {
  final GiftController _giftController = Get.put(GiftController());

  GiftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Page'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              final id = Random().nextInt(100000);
              _giftController.addGift(Gift('$id', 1));
            },
            child: const Text('Send Gift'),
          ),
          const SizedBox(height: 20),
          Obx(() {
            final first = _giftController.queue.safeGet(0);
            final secound = _giftController.queue.safeGet(1);

            return Column(children: [
              first != null
                  ? GiftAnimation(
                      key: ValueKey(first.id),
                      gift: first,
                      onAnimationComplete: _giftController._playNextAnimation,
                      animationController: _giftController._animationControllers[0],
                    )
                  : const SizedBox(
                      width: 100,
                      height: 100,
                    ),
              secound != null
                  ? GiftAnimation(
                      key: ValueKey(secound.id),
                      gift: secound,
                      onAnimationComplete: _giftController._playNextAnimation,
                      animationController: _giftController._animationControllers[1],
                    )
                  : const SizedBox(
                      width: 100,
                      height: 100,
                    ),
            ]);
          }),
        ],
      ),
    );
  }
}

class GiftAnimation extends StatefulWidget {
  final Gift gift;
  final VoidCallback onAnimationComplete;
  final AnimationController animationController;

  const GiftAnimation({
    Key? key,
    required this.gift,
    required this.onAnimationComplete,
    required this.animationController,
  }) : super(key: key);

  @override
  _GiftAnimationState createState() => _GiftAnimationState();
}

class _GiftAnimationState extends State<GiftAnimation> {
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();

    _animation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: const Offset(0.1, 0),
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.fastOutSlowIn,
    ));

    widget.animationController.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          widget.animationController.reverse().whenComplete(() {
            print('${widget.animationController} finished');
            widget.onAnimationComplete();
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text('Gift Animation for ${widget.gift.id}'),
        ),
      ),
    );
  }
}

class GiftController extends GetxController with GetTickerProviderStateMixin {
  final _queue = <Gift>[].obs;
  final _maxConcurrentAnimations = 2;

  final List<AnimationController> _animationControllers = [];
  final List<RxBool> _animationStates = <RxBool>[].obs;

  List<Gift> get queue => _queue.toList();

  @override
  void onInit() {
    super.onInit();
    for (var i = 0; i < _maxConcurrentAnimations; i++) {
      _animationControllers.add(
        AnimationController(
          duration: const Duration(milliseconds: 1200),
          vsync: this,
        ),
      );
      _animationStates.add(false.obs);
    }
    _playNextAnimation();
  }

  void addGift(Gift gift) {
    final existingGift = _queue.firstWhere((g) => g.id == gift.id, orElse: () => Gift('', 0));
    if (existingGift.id.isNotEmpty) {
      existingGift.num += gift.num;
    } else {
      _queue.add(gift);
    }
  }

  void _playNextAnimation() async {
    for (var i = 0; i < _animationControllers.length; i++) {
      if (_queue.isNotEmpty && !_animationStates[i].value) {
        final currentGift = _queue[0];
        final currentAnimationController = _animationControllers[i];

        _animationStates[i].value = true;

        await currentAnimationController.forward().then((_) async {
          await Future.delayed(const Duration(milliseconds: 2500)); // Optional delay

          _queue.removeAt(0);
          _animationStates[i].value = false;

          _playNextAnimation(); // Play the next animation after current one completes
        });
        break;
      }
    }
  }

  @override
  void onClose() {
    super.onClose();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
  }
}
