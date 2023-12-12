import 'package:flutter/material.dart';
import 'package:getx_demo1/app/widgets/emblem_list_page.dart';

class SliverTabListView extends StatefulWidget {
  const SliverTabListView({Key? key}) : super(key: key);

  @override
  _SliverTabListViewState createState() => _SliverTabListViewState();
}

class _SliverTabListViewState extends State<SliverTabListView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200.0, // 这里设置一个固定的高度
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200, // 第一个子控件高度
                    color: Colors.grey,
                    alignment: Alignment.center,
                    child: const Text('header view'),
                  ),
                  // 其他内容
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Container(
                color: Colors.blue,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Tab 1'),
                    Tab(text: 'Tab 2'),
                    Tab(text: 'Tab 3'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: const PageViewDemo(),
        // body: TabBarView(
        //   controller: _tabController,
        //   children: [
        //     _buildListView(20, 'Tab 1'),
        //     _buildListView(15, 'Tab 2'),
        //     _buildListView(10, 'Tab 3'),
        //   ],
        // ),
      ),
    );
  }

  Widget _buildListView(int itemCount, String tabTitle) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(title: Text('$tabTitle - Item $index'));
      },
    );
  }
}
