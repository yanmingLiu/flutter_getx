import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_demo1/app/modules/add/views/add_view.dart';
import 'package:getx_demo1/app/modules/friend/views/friend_view.dart';
import 'package:getx_demo1/app/modules/messages/views/messages_view.dart';
import 'package:getx_demo1/app/modules/profile/views/profile_view.dart';
import 'package:getx_demo1/app/modules/videoFeed/views/video_feed_view.dart';

class HomeController extends GetxController {
  final currentIndex = 0.obs;

  List<Widget> pages = const [
    VideoFeedView(),
    FriendView(),
    AddView(),
    MessagesView(),
    ProfileView(),
  ];

  void onTap(int index) {
    currentIndex.value = index;
  }

}
