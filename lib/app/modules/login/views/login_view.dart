import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getx_demo1/app/widgets/bottom_text_field.dart';
import 'package:getx_demo1/app/routes/app_pages.dart';
import 'package:getx_demo1/generated/locales.g.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(LocaleKeys.login.tr),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
              child: Image.asset(
            'assets/images/friend_bg.png',
            fit: BoxFit.cover,
          )),
          Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  Get.offAllNamed(AppPages.INITIAL);
                },
                child: Text(LocaleKeys.login.tr),
              ),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    controller.bottomTextFieldVisibility.value = true;
                  },
                  child: const Text('弹出底部输入框组件'),
                ),
              ),
              Expanded(
                child: Container(),
              ),
              SizedBox(
                height: Get.mediaQuery.padding.bottom,
              )
            ],
          ),
          Obx(() {
            if (controller.bottomTextFieldVisibility.value) {
              return BottomTextField(
                onTapSend: (text) {
                  // Hide the text field on submit
                  debugPrint('onTapSend:$text');
                  controller.bottomTextFieldVisibility.value = false;
                },
              );
            } else {
              return Container();
            }
          }),
        ],
      ),
    );
  }
}
