import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getx_demo1/app/routes/app_pages.dart';
import 'package:getx_demo1/generated/locales.g.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.login.tr),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Get.offAllNamed(AppPages.INITIAL);
              },
              child: Text(LocaleKeys.login.tr),
            )
          ],
        ),
      ),
    );
  }
}
