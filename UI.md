### prevent出来的页面 appbar的返回键不生效

    GetPage(
      name: xx,
      page: () => xx(),
      transition: Transition.downToUp,
      popGesture: false,
      preventDuplicates: true,
      fullscreenDialog: true,
    ),

**页面层面强制不显示左侧按钮**：在该页面的 AppBar 里设置 automaticallyImplyLeading: false
