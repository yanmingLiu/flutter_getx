import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_demo1/app/modules/profile/views/over_layer_ball.dart';
import 'package:getx_demo1/app/theme/theme_service.dart';
import 'package:getx_demo1/generated/locales.g.dart';

import '../../../routes/app_pages.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ProfileView'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              leading: Obx(() {
                return Icon(ThemeService.to.getThemeIcon());
              }),
              title: Text(
                LocaleKeys.light_mode.tr,
              ),
              onTap: () => _changeTheme(),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(
                LocaleKeys.language.tr,
              ),
              onTap: () => _changeLanguage(),
            ),
            ListTile(
              leading: const Icon(Icons.back_hand),
              title: Text(
                LocaleKeys.overlayer.tr,
              ),
              onTap: () => _showBall(context),
            ),
            ListTile(
              leading: const Icon(Icons.golf_course),
              title: const Text(
                '自定义TabBar+pageView',
              ),
              onTap: () {
                Get.toNamed(Routes.tabView);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBall(BuildContext context) {
    OverLayerBall.show(
      context: context,
      horizontalMargin: 8.0,
      bottomMargin: 100,
      child: GestureDetector(
        onTap: () {
          print('object');
          OverLayerBall.remove();
        },
        child: Container(
          width: 68,
          height: 80,
          color: Colors.amber,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 24,
                  height: 24,
                  color: Colors.red,
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: RotatingContainer(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      border: Border.all(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeLanguage() {
    Get.bottomSheet(
      IntrinsicHeight(
        child: Container(
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(LocaleKeys.chinese.tr),
                onTap: () {
                  Get.back();
                  Get.updateLocale(const Locale('zh', 'CN'));
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(LocaleKeys.english.tr),
                onTap: () {
                  Get.back();
                  Get.updateLocale(const Locale('en', 'US'));
                },
              ),
              SizedBox(height: Get.mediaQuery.padding.bottom)
            ],
          ),
        ),
      ),
    );
  }

  void _changeTheme() {
    Get.bottomSheet(
      IntrinsicHeight(
        child: Container(
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: Text(LocaleKeys.light_mode.tr),
                onTap: () {
                  ThemeService.to.switchThemeModel(ThemeEnum.light);
                  Get.back();
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: Text(LocaleKeys.dark_model.tr),
                onTap: () {
                  ThemeService.to.switchThemeModel(ThemeEnum.dark);
                  Get.back();
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_iphone),
                title: Text(LocaleKeys.system_model.tr),
                onTap: () {
                  ThemeService.to.switchThemeModel(ThemeEnum.system);
                  Get.back();
                },
              ),
              SizedBox(height: Get.mediaQuery.padding.bottom)
            ],
          ),
        ),
      ),
    );
  }
}
