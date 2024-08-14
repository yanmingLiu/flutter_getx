import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:getx_demo1/app/routes/app_route.dart';
import 'package:getx_demo1/app/theme/theme_service.dart';
import 'package:getx_demo1/app/widgets/image_slider.dart';
import 'package:getx_demo1/app/widgets/over_layer_ball.dart';
import 'package:getx_demo1/generated/locales.g.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ProfileView'),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  scalePoint(context);
                },
                icon: const Icon(Icons.help),
              );
            },
          ),
        ],
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
                Get.toNamed(AppRoute.tabView);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text(
                '数据库操作',
              ),
              onTap: () {
                Get.toNamed(AppRoute.dbView);
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_exploration),
              title: const Text(
                '数据库预览',
              ),
              onTap: () {
                Get.toNamed(AppRoute.dbPreview);
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_exploration),
              title: const Text(
                'ImageSlider',
              ),
              onTap: () {
                Get.to(const ImageSlider());
              },
            ),
          ],
        ),
      ),
    );
  }

  void scalePoint(BuildContext context) {
    SmartDialog.showAttach(
      targetContext: context,
      alignment: Alignment.bottomCenter,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.fromLTRB(60, 0, 10, 0),
          child: Stack(
            alignment: Alignment.topRight,
            children: <Widget>[
              Container(
                width: 20,
                height: 20,
                color: Colors.white,
                transform: Matrix4.rotationZ(pi / 4),
              ),
              Container(
                margin: const EdgeInsets.only(top: 7),
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: const Text(
                  '1 text message: 2 gems\n1 audio message: 4 gems\nCall AI characters: 10 gems/min\nGenerate image: 8 gems/image\nGenerate video: 10 gems/video',
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
        );
      },
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
