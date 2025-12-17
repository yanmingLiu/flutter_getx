import 'package:flutter/material.dart';

class NestedHeaderTabPage extends StatefulWidget {
  const NestedHeaderTabPage({super.key});

  @override
  _NestedHeaderTabPageState createState() => _NestedHeaderTabPageState();
}

class _NestedHeaderTabPageState extends State<NestedHeaderTabPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final tabs = ["页面一", "页面二", "页面三"];
  // TabBar 的高度
  double tabBarHeight = 46.0;
  // TabBar 上面 header高度
  double headerHeight = 40.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // 1. 获取状态栏高度
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    // 2. 计算吸顶高度 (minHeight)
    // 如果你需要留出标题栏位置（比如左边有返回键），加上 kToolbarHeight
    // 如果你只要 TabBar 吸顶，标题栏也不要，那就：statusBarHeight + 46
    final double maxHeight = statusBarHeight + kToolbarHeight + tabBarHeight + headerHeight;

    final double minHeight = statusBarHeight + tabBarHeight + headerHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          image: DecorationImage(
            // 为了演示方便，我换回了网络图，你用你的 AssetImage("test_bg".png) 即可
            image: AssetImage('assets/images/82449.jpeg'),
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverPersistentHeader(
                pinned: true,
                delegate: _CustomHeaderDelegate(
                  minHeight: minHeight,
                  maxHeight: maxHeight,
                  tabController: _tabController,
                  tabs: tabs,
                  tabBarHeight: tabBarHeight,
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: tabs.map((e) => _buildPage(e)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(String title) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: 50,
      itemBuilder: (_, i) => Container(
        color: Colors.red,
        child: ListTile(
          title: Text("$title - item $i"),
        ),
      ),
    );
  }
}

class _CustomHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final TabController tabController;
  final List<String> tabs;
  final double tabBarHeight;

  _CustomHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.tabController,
    required this.tabs,
    required this.tabBarHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      // 背景保持不动
      decoration: BoxDecoration(
        color: Colors.white,
        image: DecorationImage(
          // 为了演示方便，我换回了网络图，你用你的 AssetImage("test_bg".png) 即可
          image: AssetImage("assets/images/82449.jpeg"),
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
        ),
      ),
      // 使用 ClipRect 裁切，防止内容滑上去后溢出 Header 区域
      child: ClipRect(
        child: Stack(
          children: [
            // 3. 顶部的 Header 文字内容
            // 修改点：去掉了 Opacity，改用 Positioned 的 top 来控制位移
            Positioned(
              // 【核心逻辑】
              // 0.0 表示初始位置。
              // -shrinkOffset 表示：手指往上滑多少像素，内容就往上移多少像素。
              // 这样模拟了自然的滚动效果。
              top: 0.0 - shrinkOffset,
              left: 0,
              right: 0,
              // 高度设置为 (最大展开高度 - TabBar高度)，
              // 这样 Center 组件就会把文字居中在 TabBar 之上的区域
              height: maxHeight - tabBarHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(),
                  Container(
                    height: 40,
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                        border: BoxBorder.all(
                          width: 1,
                          color: Colors.red,
                        )),
                  ),
                ],
              ),
            ),

            // 5. 底部的 TabBar (始终固定在底部)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: tabBarHeight,
                color: Colors.transparent,
                child: TabBar(
                  controller: tabController,
                  tabs: tabs.map((e) => Tab(text: e)).toList(),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  indicatorWeight: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CustomHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight;
  }
}
