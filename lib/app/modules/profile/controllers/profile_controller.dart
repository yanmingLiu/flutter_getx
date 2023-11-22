import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_demo1/app/modules/profile/views/OverLayerBall.dart';

class ProfileController extends GetxController {
  void showBall(BuildContext context) {
    OverLayerBall.show(
      context: context,
      newView: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
        ),
      ),
    );
  }
}
