import 'package:flutter/material.dart';

class TabPageView extends StatefulWidget {
  final List<String> tabTitles;
  final List<Widget> tabContents;
  final double tabHeight;
  final Widget Function(BuildContext context, int index) separatorBuilder;
  final Color? backgroundColor;
  final Color selectedColor;
  final Color defaultColor;
  final TextStyle selectedTextStyle;
  final TextStyle defaultTextStyle;
  final EdgeInsetsGeometry tabPadding;
  final EdgeInsetsGeometry tabBarPadding;
  final bool animatedPageSwitch;

  const TabPageView({
    Key? key,
    required this.tabTitles,
    required this.tabContents,
    required this.tabHeight,
    required this.separatorBuilder,
    this.backgroundColor = Colors.transparent,
    required this.selectedColor,
    required this.defaultColor,
    required this.selectedTextStyle,
    required this.defaultTextStyle,
    required this.tabPadding,
    required this.tabBarPadding,
    this.animatedPageSwitch = false,
  }) : super(key: key);

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
  }

  void _scrollToSelectedTab(int index) {
    final selectedTabIndex = index;
    final selectedTabText = widget.tabTitles[selectedTabIndex];
    final textPainter = TextPainter(
      text: TextSpan(text: selectedTabText, style: widget.selectedTextStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final tabWidth = textPainter.width + widget.tabPadding.horizontal;
    final scrollToOffset = (selectedTabIndex - 1) * tabWidth;
    final containerWidth = MediaQuery.of(context).size.width - widget.tabBarPadding.horizontal;

    if (scrollToOffset < containerWidth / 2) {
      _scrollController.jumpTo(0);
    } else if (scrollToOffset > _scrollController.position.maxScrollExtent - containerWidth / 2) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    } else {
      _scrollController.jumpTo(scrollToOffset);
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
              return _buildTab(widget.tabTitles[index], index);
            },
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _handleTabSelection,
            children: widget.tabContents,
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String text, int index) {
    return GestureDetector(
      onTap: () {
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
      child: Container(
        padding: widget.tabPadding,
        decoration: BoxDecoration(
          color: _selectedTabIndex == index ? widget.selectedColor : widget.defaultColor,
          borderRadius: BorderRadius.circular(widget.tabHeight / 2),
        ),
        child: Center(
          child: Text(
            text,
            style: _selectedTabIndex == index ? widget.selectedTextStyle : widget.defaultTextStyle,
          ),
        ),
      ),
    );
  }
}
