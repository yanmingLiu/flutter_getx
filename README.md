## 国际化

* [get_cli](https://github.com/jonataslaw/get_cli/blob/master/README-zh_CN.md)

在 assets/locales 目录创建 json 格式的语言文件 运行 :

```
get generate locales assets/locales
```

## 常用库

```

  # 工具
  get: ^4.6.6
  get_storage: ^2.1.1
  logger: ^2.4.0
  dio: ^5.7.0
  connectivity_plus: ^6.1.0
  uuid: ^4.5.1
  device_info_plus: ^11.1.0
  package_info_plus: ^8.1.0
  video_player: ^2.9.2
  url_launcher: ^6.3.1
  android_id: ^0.4.0
  permission_handler: ^11.3.1
  speech_to_text: ^7.0.0
  audioplayers: ^6.1.0
  vibration: ^2.0.1
  fast_rsa: ^3.6.6
  flutter_image_compress: ^2.3.0
  app_links: ^6.3.2
  app_tracking_transparency: ^2.0.6

  # 内购
  in_app_purchase: ^3.2.0
  in_app_purchase_storekit: ^0.3.18+1
  in_app_purchase_android: ^0.3.6+10
  flutter_secure_storage: ^9.2.2

  # 数据库
  drift: ^2.21.0
  drift_sqflite: ^2.0.1
  sqlite3_flutter_libs: ^0.5.26
  drift_db_viewer: ^2.1.0
  path_provider: ^2.1.4

  # UI
  flutter_smart_dialog: ^4.9.8+3
  extended_image: ^8.3.1
  flutter_screenutil: ^5.9.3
  flutter_svg: ^2.0.10+1
  easy_refresh: ^3.4.0
  wechat_assets_picker: ^9.2.0
  scroll_to_index: ^3.0.1
  loading_animation_widget: ^1.3.0
  photo_view: ^0.15.0

  # 业务
  adjust_sdk: ^5.0.2
  firebase_core: ^3.8.0
  firebase_remote_config: ^5.1.5
  firebase_analytics: ^11.3.5
```

## 数据库

### [hive_flutter](https://hivedb.dev/#/)

### [Drift](https://drift.simonbinder.eu/docs/getting-started/)

依赖项

```
dependencies:
  drift: ^2.21.0
  drift_sqflite: ^2.0.1
  sqlite3_flutter_libs: ^0.5.26
  path_provider: ^2.1.4
  drift_db_viewer: ^2.1.0

dev_dependencies:
  drift_dev: ^2.21.0
  build_runner: ^2.4.13

```

**drift**：
这是定义用于访问漂移数据库的 API 的核心包。

**sqlite3_flutter_libs**：
将最新版本与您的 Android 或 iOS 应用一起发布。当您不sqlite3使用 Flutter 时，这不是必需的，但那时您需要注意包括自己。有关其他平台的概述，请参阅平台。请注意，该软件包将包含以下架构的原生 sqlite3 库：、和。大多数 Flutter 应用无法在 32 位 x86 设备上运行，除非进行进一步设置，因此如果您不需要构建，则应向您添加一个代码片段。否则，Play Store 可能会允许设备上的用户安装您的应用，即使它不受支持。在 Flutter 当前的原生构建系统中，drift 不幸无法为您做到这一点。

**path_providerand**:
path：用于查找合适的位置来存储数据库。由 Flutter 和 Dart 团队维护。

**drift_dev：**
此仅供开发使用的依赖项会根据您的表生成查询代码。它不会包含在您的最终应用中。

**build_runner：**
常用的代码生成工具，由 Dart 团队维护。

```
dart run build_runner clean
dart run build_runner build
```

监视源代码中的更改并通过增量重建生成代码。这适用于开发会话

```
dart run build_runner watch   
```

删除生成的代码：

```
dart run build_runner build --delete-conflicting-outputs
```

### floor

是一个数据库orm工具 pubspec.yaml添加以下依赖，floor_generator和build_runner是协助生成数据库代码，
命令是 flutter packages pub run build_runner build，
生成后如果有改动则用flutter packages pub run build_runner watch，
让生成的代码保持最新。

```
dependencies:
  floor: ^1.3.0  # SQLite工具

dev_dependencies:
  floor_generator: ^1.3.0
  build_runner: ^2.1.2
```

## 数据库对比

| 数据库类型   |      插件      |  特点 | 使用场景
|:----------|:-------------|:------|:------|
关系型数据库 |	sqflite	|轻量级关系型数据库，支持 SQL 查询。|	需要关系型结构和事务操作的场景。
||drift|	类型安全、自动生成代码，适合复杂查询和关系型数据。	|需要强类型安全和复杂查询。
NoSQL 数据库	|hive|	高性能二进制存储，支持自定义对象存储和加密。|	存储复杂对象和本地缓存。
||objectbox|	性能高，支持 Dart 原生对象存储和数据观察。|	高性能、高并发场景。
||cloud_firestore|	云端存储，支持实时同步和强大查询能力。	|需要实时同步和云端数据存储。
|键值存储|	get_storage|	轻量级键值存储，简单快速。|	小型设置、用户偏好存储。

## 问题：

* 当使用底部弹出页面的时候，前一个页面会向左移动一下，配置路由的时候添加fullscreenDialog: true, 解决问题。

```

GetPage(

      name: subscribePageB3,
      page: () => const SubscribePageB3(),
      transition: Transition.downToUp,
      fullscreenDialog: true,
    ),

```

### [GetxController释放问题](https://juejin.cn/post/7005003323753365517)

在我们使用GetX的时候，可能没什么GetxController未被释放的感觉，这种情况，是因为我们一般都是用了getx的那一套路由跳转api（Get.to、Get.toName...）之类：使用Get.toName，肯定需要使用GetPage；如果使用Get.to，是不需要在GetPage中注册的，Get.to的内部有一个添加到GetPageRoute的操作
通过上面会在GetPage注册可知，说明在我们跳转页面的时候，GetX会拿你到页面信息存储起来，加以管理，下面俩种场景会导致GetxController无法释放

GetxController可被自动释放的条件
* GetPage+Get.toName配套使用，可释放
* 直接使用Get.to，可释放

GetxController无法被自动释放场景
* 未使用GetX提供的路由跳转：直接使用原生路由api的跳转操作
* 这样会直接导致GetX无法感知对应页面GetxController的生命周期，会导致其无法释放

有个最优解方案，就算你不使用Getx路由，也能很轻松回收各个页面的GetXController

```dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage,
      ///此处配置下！
      navigatorObservers: [GetXRouterObserver()],
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

```
