import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getx_demo1/app/widgets/seat_view.dart';

import '../controllers/friend_controller.dart';

class FriendView extends GetView<FriendController> {
  const FriendView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FriendView'),
      ),
      body: SeatView(),
    );
  }
}
