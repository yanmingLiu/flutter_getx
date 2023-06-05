import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getx_demo1/app/theme/theme_service.dart';
import 'package:getx_demo1/generated/locales.g.dart';

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
          ],
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
