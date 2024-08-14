import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:get/get.dart';
import 'package:getx_demo1/app/db/database.dart';
import 'package:getx_demo1/app/modules/profile/views/db_view.dart';
import 'package:getx_demo1/app/widgets/image_slider.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/profile/views/custom_tab_view.dart';

class AppRoute {
  AppRoute._();

  // 路由路径常量
  static const String mian = '/';
  static const String login = '/login';
  static const String tabView = '/tabView';
  static const String dbView = '/dbView';
  static const String dbPreview = '/dbPreview';
  static const String imageSlider = '/imageSlider';

  // 路由定义列表
  static final List<GetPage> routes = [
    GetPage(name: mian, page: () => const HomeView(), binding: HomeBinding()),
    GetPage(name: login, page: () => const LoginView(), binding: LoginBinding()),
    GetPage(name: tabView, page: () => const CustomTabView()),
    GetPage(name: dbView, page: () => const DbView()),
    GetPage(name: dbPreview, page: () => DriftDbViewer(Database())),
    GetPage(
      name: imageSlider,
      page: () => const ImageSlider(),
      popGesture: false,
      preventDuplicates: true, // 防止重复进入
    ),
  ];
}
