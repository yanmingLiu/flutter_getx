import 'package:get/get.dart';
import 'package:getx_demo1/app/modules/add/controllers/add_controller.dart';
import 'package:getx_demo1/app/modules/friend/controllers/friend_controller.dart';
import 'package:getx_demo1/app/modules/messages/controllers/messages_controller.dart';
import 'package:getx_demo1/app/modules/profile/controllers/profile_controller.dart';
import 'package:getx_demo1/app/modules/videoFeed/controllers/video_feed_controller.dart';

import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );
    Get.lazyPut<FriendController>(
      () => FriendController(),
    );
    Get.lazyPut<AddController>(
      () => AddController(),
    );
    Get.lazyPut<MessagesController>(
      () => MessagesController(),
    );
    Get.lazyPut<ProfileController>(
      () => ProfileController(),
    );
    Get.lazyPut<VideoFeedController>(
      () => VideoFeedController(),
    );
  }
}
