## 错误

```error>
Launching lib/main.dart on iPhone 17 Pro in debug mode...

Xcode build done.                                           12.6s

Failed to build iOS app

Parse Issue (Xcode): Module 'adjust_sdk' not found

/Users/ai3/Documents/soul_talk/ios/Runner/GeneratedPluginRegistrant.m:11:8

Could not build the application for the simulator.

Error launching application on iPhone 17 Pro.

```

config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'

## 解决

问题还在于 Pods 为模拟器排除了 arm64 ，在 Apple Silicon 上会导致 adjust_sdk 模块未编译，从而在编译 GeneratedPluginRegistrant.m 时出现 “Module not found”。

已为你修改

* ios/Podfile ：
  + use_frameworks! 已改为静态链接： use_frameworks! :linkage => :static
  + 移除模拟器 arm64 排除： EXCLUDED_ARCHS[sdk=iphonesimulator*] 设为空
请按以下顺序重新安装并构建

* flutter clean
* rm -rf ios/Pods ios/Podfile.lock
* flutter pub get
* cd ios && pod repo update && pod install && cd ..
* 使用 Runner.xcworkspace 构建或执行： flutter run

## 问题：

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
