# Android 启动图标（静态 PNG）

本项目使用静态 PNG 作为 Android 启动图标，以保持设备桌面显示固定的“棕色背景 + 白色 Logo”品牌效果。

## 资源结构

```text
android/app/src/main/res/
  mipmap-mdpi/ic_launcher.png       # 48×48 px
  mipmap-hdpi/ic_launcher.png       # 72×72 px
  mipmap-xhdpi/ic_launcher.png      # 96×96 px
  mipmap-xxhdpi/ic_launcher.png     # 144×144 px
  mipmap-xxxhdpi/ic_launcher.png    # 192×192 px
  drawable/ic_splash_background.xml
  drawable/ic_splash_foreground.xml
  drawable-anydpi-v31/splash_screen_icon.xml
  values-v31/styles.xml
  values-night-v31/styles.xml
```

`AndroidManifest.xml` 只需要声明：

```xml
<application android:icon="@mipmap/ic_launcher">
```

不要保留 `mipmap-anydpi-v26/ic_launcher.xml` 。Android 8+ 会优先使用该 Adaptive Icon 定义，部分桌面会重绘背景、形状或颜色，导致品牌图标外观变化。

## 生成 PNG

准备两张同尺寸源图：

* `ic_launcher_background.png`：不透明的棕色背景。
* `ic_launcher_foreground.png`：透明背景的白色 Logo。

将两图按相同画布尺寸合成后，分别导出为 48、72、96、144、192 像素的 PNG，并放入对应 `mipmap-*` 目录。前景不要单独放入 `mipmap-*` ，因为静态图标只使用合成后的 `ic_launcher.png` 。

## Android 12+ 启动页

创建目录 `android/app/src/main/res/values-v31/` ，并创建 `styles.xml` ：

```xml
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowSplashScreenBackground">@android:color/white</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_screen_icon</item>
        <item name="android:windowSplashScreenIconBackgroundColor">@android:color/transparent</item>
        <item name="android:windowSplashScreenAnimationDuration">0</item>
    </style>
</resources>
```

`splash_screen_icon.xml` 是只供 Android 12+ 启动页使用的 Adaptive Icon：背景和前景均为 Vector Drawable。它不会影响桌面图标，因为 Manifest 仍只引用 `@mipmap/ic_launcher` 的静态 PNG。启动页会额外缩放和裁切 Adaptive Icon，因此本项目将原始 66×66 前景缩放到约 42×42，并居中到 108×108 画布，避免 Logo 在圆角底内显得过大。

如需夜间模式同样保持白色启动页，在 `values-night-v31/styles.xml` 创建同名样式。

## 更新检查清单

1. 前景与背景源图尺寸一致；前景保留透明通道。
2. 所有五套 `mipmap-*` 均有合成后的 `ic_launcher.png`。
3. `AndroidManifest.xml` 只引用 `@mipmap/ic_launcher`。
4. 不存在 `mipmap-anydpi-v26/ic_launcher.xml` 或 `ic_launcher_round.xml`。
5. `values-v31/styles.xml` 引用 `@drawable/splash_screen_icon`，而不是桌面 PNG。
6. 修改图标后，完整卸载并重装应用，再检查桌面图标与启动页。
