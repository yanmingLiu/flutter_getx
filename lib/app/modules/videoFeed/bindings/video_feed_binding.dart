import 'package:get/get.dart';

import '../controllers/video_feed_controller.dart';

class VideoFeedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VideoFeedController>(
      () => VideoFeedController(),
    );
  }
}
