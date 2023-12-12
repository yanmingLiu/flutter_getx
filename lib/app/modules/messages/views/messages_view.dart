import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_demo1/app/widgets/emblem_list_page.dart';

import '../controllers/messages_controller.dart';

class MessagesView extends GetView<MessagesController> {
  const MessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: NestScrollViewPage(),
    );
  }
}
