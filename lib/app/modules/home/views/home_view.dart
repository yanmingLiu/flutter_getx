import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getx_demo1/generated/locales.g.dart';

import '../controllers/home_controller.dart';
import 'custom_icon.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return IndexedStack(
          index: controller.currentIndex.value,
          children: controller.pages,
        );
      }),
      bottomNavigationBar: Obx(
        () {
          return BottomNavigationBar(
            onTap: (index) => controller.onTap(index),
            currentIndex: controller.currentIndex.value,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home, size: 30),
                label: LocaleKeys.home.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.search, size: 30),
                label: LocaleKeys.friend.tr,
              ),
              const BottomNavigationBarItem(
                icon: CustomIcon(),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.message, size: 30),
                label: LocaleKeys.messages.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person, size: 30),
                label: LocaleKeys.profile.tr,
              ),
            ],
          );
        },
      ),
    );
  }
}
