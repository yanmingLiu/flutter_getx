import 'package:flutter/material.dart';

class TabPageView extends StatefulWidget {
  final List<String> tabTitles;
  final List<Widget> tabContents;
  final double tabHeight;
  final Widget Function(BuildContext context, int index) separatorBuilder;
  final Widget Function(BuildContext context, int index, bool isSelected) itemBuilder;
  final Color? backgroundColor;
  final EdgeInsetsGeometry tabPadding;
  final EdgeInsetsGeometry tabBarPadding;
  final bool animatedPageSwitch;
  final bool allowSwipe; // 是否允许手势滑动
  final ValueChanged<int>? onPageChanged;

  const TabPageView({
    super.key,
    required this.tabTitles,
    required this.tabContents,
    required this.tabHeight,
    required this.separatorBuilder,
    required this.itemBuilder,
    this.backgroundColor = Colors.transparent,
    required this.tabPadding,
    required this.tabBarPadding,
    this.animatedPageSwitch = false,
    this.allowSwipe = true, // 默认允许滑动
    this.onPageChanged,
  });

  @override
  State<TabPageView> createState() => _TabPageViewState();
}

class _TabPageViewState extends State<TabPageView> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late ScrollController _scrollController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabSelection(int index) async {
    // 避免重复触发逻辑
    if (_selectedTabIndex == index) return;

    // 更新选中的 Tab 状态
    setState(() {
      _selectedTabIndex = index;
    });

    // 滚动到指定 Tab
    await _scrollToSelectedTab(index);

    // 滚动完成后执行回调
    widget.onPageChanged?.call(index);
  }

  Future<void> _scrollToSelectedTab(int index) async {
    final tabWidth = MediaQuery.of(context).size.width / 3; // 每个 Tab 的宽度
    final targetOffset = index * tabWidth - (MediaQuery.of(context).size.width - tabWidth) / 2;

    // 计算目标偏移量
    final scrollOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    // 滚动到目标偏移量
    return _scrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: widget.tabHeight,
          color: widget.backgroundColor,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.tabTitles.length,
            separatorBuilder: widget.separatorBuilder,
            padding: widget.tabBarPadding,
            itemBuilder: (context, index) {
              return _buildTab(index);
            },
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _handleTabSelection,
            physics: widget.allowSwipe
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(), // 根据 allowSwipe 设置滑动行为
            children: widget.tabContents,
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        _handleTabSelection(index);
        if (widget.animatedPageSwitch) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.jumpToPage(index);
        }
      },
      child: widget.itemBuilder(context, index, isSelected),
    );
  }
}
