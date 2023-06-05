import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/routes/app_pages.dart';
import 'app/theme/theme_service.dart';
import 'generated/locales.g.dart';

void main() async {
  await GetStorage.init();

  // 初始 flutter 引擎
  WidgetsFlutterBinding.ensureInitialized();

  Get.put<ThemeService>(ThemeService());

  runApp(
    GetMaterialApp(
      title: "Application",
      translationsKeys: AppTranslation.translations,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      locale: const Locale('zh', 'CN'),
      localeListResolutionCallback: (locales, supportedLocales) {
        debugPrint('当前系统语言环境:$locales');
        return;
      },
      theme: ThemeService.to.themeData,
      themeMode: ThemeMode.light, // ⚠️Fixes Theme not changing on System Dark Mode
    ),
  );
  // 修改安卓状态栏颜色
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
  }
}
