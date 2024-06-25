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
sqflite: ^2.3.3+1
sqlite3_flutter_libs: ^0.5.21
sqlite_viewer: ^1.0.5
drift: ^2.18.0

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
