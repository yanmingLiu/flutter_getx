import 'package:flutter/material.dart';
import 'package:getx_demo1/app/constants/ext.dart';
import 'package:getx_demo1/app/widgets/keep_alive_wrapper.dart';
import 'package:getx_demo1/app/widgets/tab_page_view.dart';

class CustomTabView extends StatelessWidget {
  const CustomTabView({super.key});

  @override
  Widget build(BuildContext context) {
    late List<String> tabTitles = [
      "热门",
      "推荐",
      "关注",
      "分类",
      "我的",
    ];

    late List<Widget> tabContents = List.generate(
      tabTitles.length,
      (index) {
        return KeepAliveWrapper(
          child: Container(
            color: ColorExt.random(),
            child: Center(
              child: Text(tabTitles[index]),
            ),
          ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('CustomTabView'),
      ),
      body: TabPageView(
        tabTitles: tabTitles,
        tabContents: tabContents,
        tabHeight: 40,
        separatorBuilder: (context, index) => const SizedBox(width: 20),
        tabPadding: const EdgeInsets.symmetric(horizontal: 20),
        tabBarPadding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (BuildContext context, int index, bool isSelected) {
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF53B4CC), Color(0xFFEBFF4C)],
                      )
                    : const LinearGradient(
                        colors: [Color(0x1AF8FFC7), Color(0x1AF8FFC7)],
                      ),
              ),
              height: 30,
              child: Text(
                tabTitles[index],
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white.withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
