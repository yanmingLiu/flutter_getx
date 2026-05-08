出现这个问题的原因是当软键盘弹出时，屏幕可用高度会减小。因为背景图片被放在了 Stack 中且未设置缩放模式，当外部容器缩减时，它会自动等比缩小以适应屏幕（默认的 BoxFit.scaleDown 行为）。

为了确保背景图片不仅不缩放/变形，且在底部被键盘遮挡时依然固定在屏幕顶部，我做了两点改动：

修正了之前的语法错误，添加了 fit: BoxFit.cover，这样图片始终会裁切以铺满整个屏幕，而不会被压缩变形。
追加了 alignment: Alignment.topCenter 参数，这样当键盘把可用区域往上顶（高度变小）时，背景图片的顶部将死死“钉”在屏幕最顶端，仅仅是被裁掉底部的一小部分，视觉上就绝对不会发生因为尺寸变化而带来的跳动。
同时我也一并帮你改好了 ai_image_list_page.dart 里的相同背景代码，您可以拉起键盘测试一下看看是不是已经完美固定了！

```dart
 Positioned.fill(
            child: Assets.images.imgBg.image(
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),   
```