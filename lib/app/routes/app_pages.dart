import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:get/get.dart';
import 'package:getx_demo1/app/db/database.dart';
import 'package:getx_demo1/app/modules/profile/views/db_view.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/profile/views/custom_tab_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;
  static const INITIAL_LOGIN = Routes.LOGIN;
  static const tabView = Routes.tabView;

  static final routes = [
    GetPage(
      name: INITIAL,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: INITIAL_LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: tabView,
      page: () => const CustomTabView(),
    ),
    GetPage(
      name: Routes.dbView,
      page: () => const DbView(),
    ),
    GetPage(
      name: Routes.dbPreview,
      page: () => DriftDbViewer(Database()),
    ),
  ];
}
