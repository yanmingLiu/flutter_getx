import 'package:flutter/material.dart';
import 'package:getx_demo1/app/widgets/kinked_tab_page_controller.dart';

class MyTabPage extends StatefulWidget {
  const MyTabPage({super.key});

  @override
  State<MyTabPage> createState() => _MyTabPageState();
}

class _MyTabPageState extends State<MyTabPage> {
  late LinkedTabPageController<String> _controller;

  @override
  void initState() {
    super.initState();
    _controller = LinkedTabPageController(
      items: [],
      onIndexChanged: (index) => print("当前选中 index: $index"),
      onItemsChanged: (items) => print("数据源更新: $items"),
    );

    // 模拟异步加载数据
    Future.delayed(const Duration(seconds: 2), () {
      _controller.updateItems(["新闻", "体育", "娱乐", "科技", "财经"]);
    });

    // 示例：在数据未就绪时提前调用 select()
    _controller.select(3); // 会等数据 ready 后自动跳转到 "科技"
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyTabPage'),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          if (_controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Tab
              SizedBox(
                height: 44,
                child: ListView.separated(
                  controller: _controller.scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _controller.items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final title = _controller.items[index];
                    return GestureDetector(
                      key: _controller.getTabKey(index),
                      onTap: () => _controller.select(index),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (_, __) {
                          final isActive = _controller.index == index;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(title,
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.black,
                                )),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              // Page
              Expanded(
                child: PageView.builder(
                  controller: _controller.pageController,
                  onPageChanged: _controller.handlePageChanged,
                  itemCount: _controller.items.length,
                  itemBuilder: (context, index) {
                    final title = _controller.items[index];
                    return Center(child: Text("页面：$title"));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
