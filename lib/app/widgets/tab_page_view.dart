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

  void _handleTabSelection(int index) {
    setState(() {
      _selectedTabIndex = index;
      _scrollToSelectedTab(index);
    });
    if (widget.onPageChanged != null) {
      widget.onPageChanged!(index);
    }
  }

  void _scrollToSelectedTab(int index) {
    final tabWidth = MediaQuery.of(context).size.width / 3; // 每个 Tab 宽度按 1/3 屏幕宽计算
    final targetOffset = index * tabWidth - (MediaQuery.of(context).size.width - tabWidth) / 2;

    if (targetOffset < 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (targetOffset > _scrollController.position.maxScrollExtent) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
