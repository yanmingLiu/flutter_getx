## 国际化

* [get_cli](https://github.com/jonataslaw/get_cli/blob/master/README-zh_CN.md)

在 assets/locales 目录创建 json 格式的语言文件 运行 :

```
get generate locales assets/locales
```

## 常用库

```
// 屏幕适配
flutter_screenutil: ^5.9.0
// 下拉刷新
easy_refresh: ^3.3.4
// 强大的官方 Image 扩展组件
extended_image: ^8.2.1
// 微信 UI 的 Flutter 图片选择器
wechat_assets_picker: ^latest_version
// dialog
flutter_smart_dialog: ^4.9.6
// 监听滚动视图中正在显示的子部件
scrollview_observer: latest_version
// 状态管理
get: ^4.6.6
// 滚动到索引
scroll_to_index: ^3.0.1
// 包信息
package_info_plus: ^8.0.0
device_info_plus: ^9.1.2
// app 生命周期监听
flutter_lifecycle_detector: ^0.0.6
// 网络监听
connectivity_plus: ^6.0.2
// 音频播放
audioplayers: ^6.0.0
// 手机状态
phone_state: ^1.0.4
// 视频播放
video_player: ^2.8.6
// 内购
in_app_purchase: ^3.1.13
in_app_purchase_storekit: ^0.3.13+1
in_app_purchase_android: ^0.3.2
// 本地存储
flutter_secure_storage: ^9.0.0
// log
logger: ^2.2.0
sprintf: ^7.0.0

// 数据库 相关
// 依赖项
dependencies:
  sqflite: ^2.3.3+1
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.0.0
  path: ^1.9.0

dev_dependencies:
  drift_dev: ^2.18.0
  build_runner: ^2.4.9

https://drift.simonbinder.eu/docs/getting-started/
Drift 是一个功能强大的数据库库，适用于 Dart 和 Flutter 应用程序。为了支持其高级功能（如类型安全的 SQL 查询、数据库验证和迁移），它使用了在编译时运行的构建器和命令行工具。

drift：这是定义用于访问漂移数据库的 API 的核心包。
sqlite3_flutter_libs：将最新版本与您的 Android 或 iOS 应用一起发布。当您不sqlite3使用 Flutter 时，这不是必需的，但那时您需要注意包括自己。有关其他平台的概述，请参阅平台。请注意，该软件包将包含以下架构的原生 sqlite3 库：、和。大多数 Flutter 应用无法在 32 位 x86 设备上运行，除非进行进一步设置，因此如果您不需要构建，则应向您添加一个代码片段。否则，Play Store 可能会允许设备上的用户安装您的应用，即使它不受支持。在 Flutter 当前的原生构建系统中，drift 不幸无法为您做到这一点。sqlite3sqlite3_flutter_libsarmv8armv7x86x86_64build.gradlex86x86
path_providerand path：用于查找合适的位置来存储数据库。由 Flutter 和 Dart 团队维护。
drift_dev：此仅供开发使用的依赖项会根据您的表生成查询代码。它不会包含在您的最终应用中。
build_runner：常用的代码生成工具，由 Dart 团队维护。

您可以通过调用build_runner来执行此操作：

dart run build_runner build一次生成所有必需的代码。
dart run build_runner watch监视源代码中的更改并通过增量重建生成代码。这适用于开发会话。

floor是一个数据库orm工具 pubspec.yaml添加以下依赖，floor_generator和build_runner是协助生成数据库代码，
命令是 flutter packages pub run build_runner build，
生成后如果有改动则用flutter packages pub run build_runner watch，
让生成的代码保持最新。

dependencies:
  floor: ^1.3.0  # SQLite工具

dev_dependencies:
  floor_generator: ^1.3.0
  build_runner: ^2.1.2

```

## 问题：

### 当使用底部弹出页面的时候，前一个页面会向左移动一下，配置路由的时候添加fullscreenDialog: true, 解决问题。

```
GetPage(
      name: subscribePageB3,
      page: () => const SubscribePageB3(),
      transition: Transition.downToUp,
      fullscreenDialog: true,
    ),
```
