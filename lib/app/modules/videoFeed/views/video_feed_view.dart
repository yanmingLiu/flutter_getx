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
      body: Center(
        child: Text(
          'VideoFeedView is working\n${controller.readTheme()}',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
