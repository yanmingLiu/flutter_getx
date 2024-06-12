import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class VideoFeedController extends GetxController {
  String readTheme() {
    String? storedValue = GetStorage().read('key_theme');
    return storedValue ?? '缓存为空';
  }

  var isOn = false.obs;
}
