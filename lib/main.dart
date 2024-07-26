import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/router_report.dart';
import 'package:get_storage/get_storage.dart';

import 'app/routes/app_route.dart';
import 'app/theme/theme_service.dart';
import 'generated/locales.g.dart';

bool isLogin = false;

void main() async {
  await GetStorage.init();

  // 初始 flutter 引擎
  WidgetsFlutterBinding.ensureInitialized();

  Get.put<ThemeService>(ThemeService());

  runApp(const App());

  // 修改安卓状态栏颜色
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: GetMaterialApp(
        title: "Application",
        debugShowCheckedModeBanner: false,
        translationsKeys: AppTranslation.translations,
        initialRoute: isLogin ? AppRoute.mian : AppRoute.login,
        getPages: AppRoute.routes,
        locale: const Locale('zh', 'CN'),
        localeListResolutionCallback: (locales, supportedLocales) {
          debugPrint('当前系统语言环境:$locales');
          return;
        },
        theme: ThemeService.to.themeData,
        // ⚠️Fixes Theme not changing on System Dark Mode
        themeMode: ThemeMode.light,
        // ⚠️ 初始化FlutterSmartDialog
        navigatorObservers: [
          FlutterSmartDialog.observer,
          GetXRouterObserver(), // 手动让getx感知路由
        ],
        builder: FlutterSmartDialog.init(),
      ),
    );
  }
}

///自定义这个关键类！！！！！！
class GetXRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    RouterReportManager.reportCurrentRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) async {
    RouterReportManager.reportRouteDispose(route);
  }
}
