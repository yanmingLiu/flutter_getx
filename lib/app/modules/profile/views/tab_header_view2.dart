import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 设置一下状态栏样式，保证沉浸式体验
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const Test2App());
}

class Test2App extends StatelessWidget {
  const Test2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NestedHeaderTabPage2(),
    );
  }
}

class NestedHeaderTabPage2 extends StatefulWidget {
  const NestedHeaderTabPage2({super.key});

  @override
  _NestedHeaderTabPage2State createState() => _NestedHeaderTabPage2State();
}

class _NestedHeaderTabPage2State extends State<NestedHeaderTabPage2> with TickerProviderStateMixin {
  late TabController _tabController;
  final tabs = ["页面一", "页面二", "页面三"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    // 固定的高度：状态栏 + 标题栏高度(kToolbarHeight) + TabBar高度(46)
    // 这里设为 120 大概是够的，但建议用精确计算，保证各个手机适配
    final double pinnedHeight = statusBarHeight + kToolbarHeight + 46;

    return Scaffold(
      body: Container(
        // decoration: BoxDecoration(
        //   color: Colors.white,
        //   image: DecorationImage(
        //     image: AssetImage("assets/images/82449.jpeg"),
        //     fit: BoxFit.fitWidth,
        //     alignment: Alignment.topCenter,
        //   ),
        // ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverPersistentHeader(
                pinned: true,
                delegate: _CustomHeaderDelegate(
                  minHeight: pinnedHeight,
                  maxHeight: 250,
                  tabController: _tabController,
                  tabs: tabs,
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
    return RefreshableListPage(title: title);
  }
}

class _CustomHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final TabController tabController;
  final List<String> tabs;

  _CustomHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.tabController,
    required this.tabs,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // 1. 获取各个区域的高度
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double tabBarHeight = 46.0;
    // 标题区域的高度 (状态栏 + 标题栏)
    final double titleSectionHeight = statusBarHeight + kToolbarHeight;

    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        image: DecorationImage(
          image: AssetImage("assets/images/82449.jpeg"),
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Stack(
        children: [
          // ==============================
          // 1. 中间滚动内容 ("我的超级主页")
          // ==============================
          // 【核心逻辑】：
          // 我们用 Positioned 限制了这个区域的 顶部 (top) 和 底部 (bottom)。
          // top 设为 titleSectionHeight，意味着它的内容绝对不会出现在标题区域内。
          Positioned(
            top: titleSectionHeight, // 顶部边界：标题栏下方
            bottom: tabBarHeight, // 底部边界：TabBar上方
            left: 0,
            right: 0,
            // 【关键点】：ClipRect 会把超出 Positioned 范围的内容剪裁掉
            // 这样当内容往上滑，碰到 top 边界时，就会直接“消失”，不会重叠到标题上
            child: ClipRect(
              child: OverflowBox(
                // OverflowBox 允许子组件的高度超出父组件的限制
                // 我们设为 maxHeight，保证内容布局时的高度和展开时一致
                minHeight: maxHeight,
                maxHeight: maxHeight,
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  // 【位移计算】：
                  // 1. Offset(0, -titleSectionHeight):
                  //    因为外层 Positioned 把我们往下推了 titleSectionHeight 的距离，
                  //    我们需要往上移回来，保证初始状态下内容位置是正确的（居中）。
                  // 2. Offset(0, -shrinkOffset):
                  //    这是随手指滑动的位移。
                  offset: Offset(0, -titleSectionHeight - shrinkOffset),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 30),
                        Icon(Icons.verified_user, size: 60, color: Colors.black),
                        Text(
                          "我的超级主页",
                          style: TextStyle(
                              color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ==============================
          // 2. 顶部固定标题 ("标题")
          // ==============================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: titleSectionHeight, // 高度明确
            child: Container(
              // 这里不需要背景色，背景图会透过来
              padding: EdgeInsets.only(top: statusBarHeight, left: 16),
              alignment: Alignment.centerLeft,
              // color: Colors.amber,
              child: Text(
                "标题",
                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // ==============================
          // 3. 底部固定 TabBar
          // ==============================
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
                dividerHeight: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CustomHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight;
  }
}

class RefreshableListPage extends StatefulWidget {
  final String title;

  const RefreshableListPage({super.key, required this.title});

  @override
  State<RefreshableListPage> createState() => _RefreshableListPageState();
}

class _RefreshableListPageState extends State<RefreshableListPage> {
  final List<String> _items = [];
  int _currentPage = 0;
  late EasyRefreshController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EasyRefreshController(
      controlFinishRefresh: true,
      controlFinishLoad: true,
    );
    // 初始化加载第一页数据
    _loadInitialData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 初始化加载数据
  Future<void> _loadInitialData() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _items.clear();
      _currentPage = 0;
      for (int i = 0; i < 10; i++) {
        _items.add("${widget.title} - item ${_currentPage * 10 + i}");
      }
      _currentPage++;
    });
  }

  // 下拉刷新
  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _items.clear();
      _currentPage = 0;
      for (int i = 0; i < 10; i++) {
        _items.add("${widget.title} - item ${_currentPage * 10 + i}");
      }
      _currentPage++;
    });
    _controller.finishRefresh(IndicatorResult.success);
  }

  // 上拉加载更多
  Future<void> _onLoad() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      for (int i = 0; i < 10; i++) {
        _items.add("${widget.title} - item ${_currentPage * 10 + i}");
      }
      _currentPage++;
    });
    _controller.finishLoad(IndicatorResult.success);
  }

  @override
  Widget build(BuildContext context) {
    return EasyRefresh(
      controller: _controller,
      onRefresh: _onRefresh,
      onLoad: _onLoad,
      header: ClassicHeader(
        dragText: '下拉刷新',
        armedText: '松开刷新',
        readyText: '加载中...',
        processingText: '加载中...',
        processedText: '加载完成',
        noMoreText: '没有更多了',
        failedText: '加载失败',
        messageText: '最后更新于 %T',
      ),
      footer: ClassicFooter(
        dragText: '上拉加载',
        armedText: '松开加载',
        readyText: '加载中...',
        processingText: '加载中...',
        processedText: '加载完成',
        noMoreText: '没有更多了',
        failedText: '加载失败',
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _items.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(_items[i]),
        ),
      ),
    );
  }
}
