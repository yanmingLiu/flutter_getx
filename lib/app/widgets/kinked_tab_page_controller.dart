import 'dart:async';

import 'package:flutter/material.dart';

/// 通用的 Tab <-> Page 联动控制器（支持动态数据源 + 懒加载）
class LinkedTabPageController<T> extends ChangeNotifier {
  List<T> _items;
  List<T> get items => _items;

  final PageController pageController;
  final ScrollController scrollController;

  final Map<int, GlobalKey> _tabKeys = {};

  int _index = 0;
  int get index => _index;

  /// 回调
  final ValueChanged<int>? onIndexChanged;
  final ValueChanged<List<T>>? onItemsChanged;

  /// 懒加载控制
  Completer<void>? _readyCompleter;

  LinkedTabPageController({
    required List<T> items,
    int initialIndex = 0,
    this.onIndexChanged,
    this.onItemsChanged,
  })  : _items = items,
        pageController = PageController(initialPage: initialIndex),
        scrollController = ScrollController() {
    _index = initialIndex.clamp(0, items.isNotEmpty ? items.length - 1 : 0);

    if (_items.isEmpty) {
      _readyCompleter = Completer<void>();
    }
  }

  /// 是否已准备好（有数据）
  bool get isReady => _items.isNotEmpty;

  /// 等待数据就绪
  Future<void> waitUntilReady() async {
    if (isReady) return;
    _readyCompleter ??= Completer<void>();
    return _readyCompleter!.future;
  }

  /// 动态更新数据源
  void updateItems(List<T> newItems) {
    _items = newItems;

    // 修正 index
    if (_index >= _items.length) {
      _index = _items.isNotEmpty ? _items.length - 1 : 0;
    }

    // 数据源更新回调
    notifyListeners();
    onItemsChanged?.call(_items);

    // 如果之前在等待数据，则唤醒
    if (_items.isNotEmpty && _readyCompleter != null && !_readyCompleter!.isCompleted) {
      _readyCompleter!.complete();
      _readyCompleter = null;
    }
  }

  /// Tab 的 key（用于滚动可见）
  GlobalKey getTabKey(int index) {
    return _tabKeys[index] ??= GlobalKey();
  }

  /// 切换到指定 Tab
  Future<void> select(int newIndex) async {
    // 等待数据准备好
    await waitUntilReady();

    if (newIndex == _index || newIndex < 0 || newIndex >= _items.length) return;

    _updateIndex(newIndex); // 先更新 index 状态

    // 如果 PageView 还没 attach，延迟执行跳转
    if (!pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!pageController.hasClients) return; // 再次检查
        _jumpOrAnimate(newIndex);
      });
    } else {
      _jumpOrAnimate(newIndex);
    }
  }

  void _jumpOrAnimate(int newIndex) {
    final currentIndex = pageController.page?.round() ?? _index;
    if ((currentIndex - newIndex).abs() == 1) {
      pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      pageController.jumpToPage(newIndex);
    }
  }

  /// PageView 滑动时调用
  void handlePageChanged(int newIndex) {
    if (_index != newIndex) {
      _updateIndex(newIndex);
    }
  }

  void _updateIndex(int newIndex) {
    _index = newIndex;
    notifyListeners();
    onIndexChanged?.call(_index);
    _scrollToTab(newIndex);
  }

  /// 保证 Tab 可见
  Future<void> _scrollToTab(int index) async {
    final key = _tabKeys[index];
    if (key == null) return;

    Future<void> ensure() async {
      final ctx = key.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    }

    if (key.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ensure());
    } else {
      await ensure();
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
