import 'package:flutter/material.dart';
import 'package:getx_demo1/app/widgets/tab_page_view.dart';

class CustomTabView extends StatelessWidget {
  const CustomTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CustomTabView'),
      ),
      body: TabPageView(
        tabTitles: const ['Tab 1', 'Tab 22', 'Tab 333', 'Tab 4444', 'Tab 55555'],
        tabContents: const [
          Center(child: Text('Content for Tab 1')),
          Center(child: Text('Content for Tab 2')),
          Center(child: Text('Content for Tab 3')),
          Center(child: Text('Content for Tab 4')),
          Center(child: Text('Content for Tab 5')),
        ],
        tabHeight: 30,
        separatorBuilder: (context, index) => const SizedBox(width: 20),
        // backgroundColor: Colors.grey.withOpacity(0.2),
        selectedColor: Colors.blue,
        defaultColor: Colors.red,
        selectedTextStyle: const TextStyle(color: Colors.white),
        defaultTextStyle: const TextStyle(color: Colors.white),
        tabPadding: const EdgeInsets.symmetric(horizontal: 12),
        tabBarPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }
}
