import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkService extends GetxService {
  var isConnected = true.obs; // 响应式的网络状态

  // 初始化时开始监听网络状态
  Future<NetworkService> init() async {
    Connectivity().onConnectivityChanged.listen((status) {
      if (status == ConnectivityResult.none) {
        isConnected.value = false;
        Get.snackbar('No Network', 'Please check your connection');
      } else {
        isConnected.value = true;
      }
    });
    return this;
  }
}
