import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/add_controller.dart';

class AddView extends GetView<AddController> {
  const AddView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AddView'),
      ),
      body: const Center(
        child: Text(
          'AddView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
