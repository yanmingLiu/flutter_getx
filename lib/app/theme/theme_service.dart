import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getx_demo1/app/theme/theme.dart';

enum ThemeEnum {
  light,
  dark,
  system,
}

class ThemeService extends GetxService with WidgetsBindingObserver {
  static ThemeService get to => Get.find();

  final _storage = GetStorage();
  final _key = "key_theme";

  final _themeEnum = ThemeEnum.light.obs;

  ThemeEnum get themeEnum => _themeEnum.value;

  @override
  void onInit() {
    super.onInit();
    _readTheme();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _changeTheme();
        break;
      default:
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  ThemeData get themeData {
    switch (themeEnum) {
      case ThemeEnum.light:
        return AppTheme.light;
      case ThemeEnum.dark:
        return AppTheme.dark;
      case ThemeEnum.system:
        return Get.isPlatformDarkMode ? AppTheme.dark : AppTheme.light;
    }
  }

  ThemeMode get themeMode {
    switch (themeEnum) {
      case ThemeEnum.light:
        return ThemeMode.light;
      case ThemeEnum.dark:
        return ThemeMode.dark;
      case ThemeEnum.system:
        return ThemeMode.system;
    }
  }

  IconData getThemeIcon() {
    switch (themeEnum) {
      case ThemeEnum.light:
        return Icons.light_mode;
      case ThemeEnum.dark:
        return Icons.dark_mode;
      case ThemeEnum.system:
        return Icons.phone_iphone;
    }
  }

  void switchThemeModel(ThemeEnum theme) {
    _themeEnum.value = theme;
    _changeTheme();
    _saveThemeModel(theme);
  }

  void _changeTheme() {
    bool isDarkModel = false;
    switch (themeEnum) {
      case ThemeEnum.light:
        isDarkModel = false;
        break;
      case ThemeEnum.dark:
        isDarkModel = true;
        break;
      case ThemeEnum.system:
        isDarkModel = Get.isPlatformDarkMode;
        break;
    }
    Get.changeTheme(
      isDarkModel ? AppTheme.dark : AppTheme.light,
    );
  }

  void _readTheme() {
    String? storedValue = GetStorage().read(_key);
    storedValue ??= ThemeEnum.light.toString();
    ThemeEnum theme = ThemeEnum.values.firstWhere(
      (e) => e.toString() == storedValue,
    );
    _themeEnum.value = theme;
    // _changeTheme();
  }

  void _saveThemeModel(ThemeEnum theme) {
    _storage.write(_key, theme.toString());
  }
}
