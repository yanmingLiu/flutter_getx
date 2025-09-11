## Flutter 安卓打包流程

> **🚀 新功能**: 本教程现在提供一键环境配置脚本 `setup_flutter_env.sh` ，可以自动完成 Flutter 和 JDK 17 的安装配置，大大简化了环境搭建过程！

### 目录

1. [前提条件](#前提条件)
   - [🚀 一键环境配置](#-一键环境配置-强烈推荐)
   - [📋 脚本执行流程](#-脚本执行流程)
   - [🔧 手动安装](#-手动安装-备选方案)
   - [✅ 环境验证](#-环境验证)
   - [🚨 常见问题](#-常见问题)
2. [配置签名密钥](#配置签名密钥)
   - [生成签名密钥](#生成签名密钥)
   - [配置密钥属性文件](#配置密钥属性文件)
   - [修改 `build.gradle` 文件](#修改-buildgradle-文件)
3. [构建发布版本](#构建发布版本)
4. [常见错误及解决方法](#常见错误及解决方法)
5. [🛠️ 自动化环境配置](#️-自动化环境配置)

---

## 前提条件

在开始之前，您需要配置 Flutter 开发环境。本教程提供了一键自动配置脚本，大大简化了环境搭建过程。

### 🚀 一键环境配置 (强烈推荐)

使用我们提供的统一配置脚本，自动完成所有环境配置：

```bash
# 下载并运行一键环境配置脚本
chmod +x setup_flutter_env.sh
./setup_flutter_env.sh
```

**脚本功能：**
* 🔍 **智能检测**：自动检测现有 Flutter 和 JDK 17 安装
* 📱 **Flutter 3.32.0**：自动下载安装或使用现有版本
* ☕ **JDK 17**：跨平台自动安装和配置
* 💎 **Ruby 环境**：macOS 上通过 rbenv 管理 Ruby 版本 (3.4.4+)
* 🍎 **CocoaPods**：macOS 上自动安装 iOS 依赖管理工具
* 🤖 **Android SDK**：自动检测和配置 Android 开发工具链
* 🔧 **环境变量**：自动配置 PATH、JAVA_HOME、ANDROID_HOME 和 rbenv
* 🧪 **环境验证**：运行 flutter doctor 检查环境
* 💾 **安全备份**：自动备份现有配置文件

**支持平台：**
* macOS (使用 Homebrew 安装 Temurin JDK 17)
* Linux (Ubuntu/Debian/CentOS/Fedora/Arch)

### 📋 脚本执行流程

1. **环境检测**：检测操作系统和 Shell 类型
2. **Flutter 检查**：
   - 如果已安装 Flutter，询问是否重新安装
   - 如果未安装，自动下载 Flutter 3.32.0 到 `~/Documents/flutter`

3. **JDK 17 检查**：
   - 如果已安装 JDK 17，询问是否重新配置
   - 如果未安装，根据系统自动安装 JDK 17

4. **Ruby 环境配置** (仅 macOS)：
   - 检测现有 Ruby 版本，如果版本过低会安装 rbenv
   - 通过 rbenv 安装最新稳定版 Ruby (3.4.4+)
   - 配置 rbenv 环境变量和 shim 路径

5. **CocoaPods 安装** (仅 macOS)：
   - 安装 CocoaPods 用于 iOS 依赖管理
   - 验证 CocoaPods 安装和版本

6. **Android SDK 配置**：
   - 自动检测 Android Studio 和 SDK 安装
   - 配置 cmdline-tools 和 platform-tools 路径
   - 自动接受 Android SDK 许可证

7. **环境配置**：自动配置所有必要的环境变量
8. **Flutter 配置**：配置 Flutter 使用 JDK 17
9. **环境验证**：运行 `flutter doctor -v` 检查环境状态

### 🔧 手动安装 (备选方案)

如果您更喜欢手动安装，可以按以下步骤操作：

#### Flutter SDK 手动安装

```bash
# 1. 克隆 Flutter 仓库
cd ~/Documents
git clone https://github.com/flutter/flutter.git -b 3.32.0

# 2. 配置环境变量 (添加到 ~/.zshrc 或 ~/.bashrc)
export PATH="$HOME/Documents/flutter/bin:$PATH"
export PATH="$HOME/.pub-cache/bin:$PATH"

# 3. 重新加载配置
source ~/.zshrc  # 或 source ~/.bashrc
flutter doctor
```

#### JDK 17 手动安装

**macOS**:

```bash
brew install --cask temurin@17
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 17)' >> ~/.zshrc
```

**Linux (Ubuntu/Debian)**:

```bash
sudo apt update && sudo apt install openjdk-17-jdk -y
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
echo 'export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"' >> ~/.bashrc
```

### ✅ 环境验证

无论使用自动脚本还是手动安装，完成后请验证环境：

```bash
# 验证 Flutter
flutter --version
flutter doctor -v

# 验证 Java
java -version
echo $JAVA_HOME

# 验证 Flutter JDK 配置
flutter config --jdk-dir="$JAVA_HOME"
```

### 🚨 常见问题

**如果出现 `command not found: flutter` ：**
1. 重新打开终端窗口
2. 或运行 `source ~/.zshrc` (或 `source ~/.bashrc`)
3. 检查 PATH 环境变量是否正确配置

**如果 flutter doctor 报告 JDK 问题：**
1. 确认 JDK 17 已正确安装
2. 运行 `flutter config --jdk-dir="$JAVA_HOME"`
3. 重新运行 `flutter doctor -v`

---

您可以通过以下命令检查 Flutter 环境配置：

```bash
flutter doctor -v
```

---

## 配置签名密钥

### a. 生成签名密钥

使用 `keytool` 命令生成签名密钥：

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

运行 `keytool` 命令后，它会要求你输入一系列信息来生成密钥库 ( `.jks` ) 文件。以下是每个字段的填写说明：

```text
Enter keystore password:         # 输入并确认密钥库密码 (请牢记)
Re-enter new password:
What is your first and last name?
  [Unknown]:  # 输入您的姓名 (可留空)
What is the name of your organizational unit?
  [Unknown]:  # 输入您的组织部门 (可留空)
What is the name of your organization?
  [Unknown]:  # 输入您的组织名称 (可留空)
What is the name of your City or Locality?
  [Unknown]:  # 输入您的所在城市 (可留空)
What is the name of your State or Province?
  [Unknown]:  # 输入您的省份 (可留空)
What is the two-letter country code for this unit?
  [Unknown]:  # 输入国家代码 (中国: CN，美国: US)
Is CN=XXX, OU=XXX, O=XXX, L=XXX, ST=XXX, C=XX correct?
  [no]: yes  # 确认信息无误
Enter key password for <upload>
  (RETURN if same as keystore password):  # 按回车使用相同的密码
```

完成后，upload-keystore.jks 文件会生成在 ~/upload-keystore.jks 目录下。

### b. 配置密钥属性文件

将 upload-keystore.jks 移动到 android/app 目录:

```properties
mv ~/upload-keystore.jks android/app/
```

在 `android` 目录下创建 `key.properties` 文件，并添加以下内容：

```properties
storeFile=upload-keystore.jks
storePassword=你的密码
keyAlias=upload
keyPassword=你的密码
```

### c. 修改 `build.gradle` 文件

编辑 `android/app/build.gradle` ，在 `android` 节点内添加以下代码：

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id "dev.flutter.flutter-gradle-plugin"
    id 'com.google.gms.google-services'
}

android {
   // TODO:
    namespace = "com.xx" 
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.xxx"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        release {
            def keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) { // 仅在文件存在时加载
                def keystoreProperties = new Properties()
                keystoreProperties.load(new FileInputStream(keystorePropertiesFile))

                storeFile file(keystoreProperties["storeFile"])
                storePassword keystoreProperties["storePassword"]
                keyAlias keystoreProperties["keyAlias"]
                keyPassword keystoreProperties["keyPassword"]
            } else {
                println("Warning: key.properties not found, skipping release signing.")
            }
        }
    }

    buildTypes {
        debug {
            signingConfig signingConfigs.debug // 确保 debug 使用默认签名
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.release
            minifyEnabled true // 开启代码混淆
            shrinkResources true // 移除无用资源
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation 'com.facebook.android:facebook-android-sdk:latest.release'
    implementation(platform("com.google.firebase:firebase-bom:33.3.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation 'com.android.installreferrer:installreferrer:2.2'
}

```

---

## 构建发布版本

运行以下命令构建 APK：

```bash
flutter build apk --release
```

或构建 AAB（适用于 Google Play）：

```bash
flutter build appbundle
```

构建完成后，APK 文件将在 `build/app/outputs/flutter-apk/` 目录下，AAB 文件将在 `build/app/outputs/bundle/release/` 目录下。

---

## 常见错误及解决方法

### 1. `Execution failed for task ':connectivity_plus:compileReleaseJavaWithJavac Could not resolve all files for configuration':connectivity_plus:androidJdkImage'.'.`

这个错误与 connectivity_plus 插件在编译时的 Java JDK 兼容性问题有关，可能是由于：

	•	你的 Java 版本 (JDK 21) 不兼容某些 Gradle 插件或 Android SDK 组件。
	•	core-for-system-modules.jar 相关的 jlink 处理失败。

**解决方案：**
 降级 JDK 版本到 JDK 17 [stackoverflow](https://stackoverflow.com/questions/79053829/could-not-resolve-all-files-for-configuration-connectivity-plusandroidjdkimag)

 指定 JDK 目录：
   

```bash
   flutter config --jdk-dir=$(/usr/libexec/java_home -v 17)
   ```

### 2. `keytool` 命令找不到

**解决方案：**
运行以下命令查找 `keytool` 的完整路径：

```bash
flutter doctor -v
```

在 `Java binary at:` 之后的路径即为 Java 可执行文件路径，使用完整路径执行 `keytool` 命令。

### 3. `The Android Gradle plugin supports only Kotlin Gradle plugin version X.X.X and higher`

**解决方案：**
1. 在 `android/build.gradle` 文件中，修改 `ext.kotlin_version` 为最新版本。
2. 在 `android/gradle/wrapper/gradle-wrapper.properties` 中，更新 `distributionUrl` 为最新版本。
3. 运行 `flutter clean`，然后重新构建项目。

---

### 4. `Android toolchain ✗ Cannot execute /Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home/bin/java to determine the version`

```
flutter doctor -v                                                                  
[✓] Flutter (Channel stable, 3.32.0, on macOS 15.5 24F74 darwin-arm64, locale zh-Hans-US) [164ms]
    • Flutter version 3.32.0 on channel stable at /Users/ai3/flutter
    • Upstream repository https://github.com/flutter/flutter.git
    • Framework revision be698c48a6 (8 weeks ago), 2025-05-19 12:59:14 -0700
    • Engine revision 1881800949
    • Dart version 3.8.0
    • DevTools version 2.45.1

[!] Android toolchain - develop for Android devices (Android SDK version 36.0.0) [138ms]
    • Android SDK at /Users/ai3/Library/Android/sdk
    • Platform android-36, build-tools 36.0.0
    • Java binary at: /Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home/bin/java
      This JDK is specified in your Flutter configuration.
      To change the current JDK, run: `flutter config --jdk-dir="path/to/jdk"`.
    ✗ Cannot execute /Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home/bin/java to determine the
      version
```

建议你以后都使用 /usr/libexec/java_home -v 17 来自动获取有效 JDK 路径

这样可以避免路径写错或用到损坏的 JDK：

```
flutter config --jdk-dir=$(/usr/libexec/java_home -v 17)
```

至此，Flutter 安卓打包流程完整，若有其他问题可参考 Flutter 官方文档或 StackOverflow 进行搜索。🚀

### 🛠️ 自动化环境配置

本教程的核心是提供的一键环境配置脚本 `setup_flutter_env.sh` ，它整合了 Flutter 和 JDK 17 的完整安装配置流程。

#### 📋 脚本详细说明

**智能检测机制：**
* 自动检测当前系统已安装的 Flutter 版本
* 检查 JDK 17 安装状态和 JAVA_HOME 配置
* 根据检测结果提供个性化的安装选项

**安装策略：**
* **Flutter**: 如果已安装，询问是否重新安装；如果未安装，自动下载 3.32.0 版本
* **JDK 17**: 如果已安装且配置正确，询问是否重新配置；否则自动安装

**跨平台支持：**
* **macOS**: 使用 Homebrew 安装 Temurin JDK 17
* **Linux**: 支持 Ubuntu/Debian (apt)、CentOS/RHEL/Fedora (yum/dnf)、Arch (pacman)

**安全特性：**
* 自动备份现有配置文件 (添加时间戳)
* 智能清理旧的环境变量配置
* 非破坏性安装，保护现有环境

#### 🚀 快速开始

```bash
# 1. 确保脚本可执行
chmod +x setup_flutter_env.sh

# 2. 运行一键配置
./setup_flutter_env.sh

# 3. 按照提示进行选择
# - 是否重新安装 Flutter (如果已存在)
# - 是否重新配置 JDK 17 (如果已存在)

# 4. 脚本完成后，验证环境
flutter doctor -v
```

#### 📊 执行结果

脚本执行完成后，您将获得：
* ✅ Flutter 3.32.0 (或保留现有版本)
* ✅ JDK 17 正确安装和配置
* ✅ Ruby 3.4.4+ 通过 rbenv 管理 (仅 macOS)
* ✅ CocoaPods 最新版本安装 (仅 macOS)
* ✅ Android SDK 和工具链正确配置
* ✅ 所有环境变量正确设置 (PATH、JAVA_HOME、ANDROID_HOME)
* ✅ Flutter 配置使用 JDK 17
* ✅ 完整的环境验证报告

#### 🔧 故障排除

如果脚本执行后遇到问题：

1. **Flutter 命令不可用**：
   

```bash
   # 检查当前使用的 Shell
   echo $SHELL
   
   # 重新加载正确的配置文件
   source ~/.zshrc    # 对于 Zsh (macOS 默认)
   source ~/.bashrc   # 对于 Bash (Linux 默认)
   
   # 或重新打开终端
   ```

2. **Shell 配置文件错误 (常见于 macOS)**：
   
   如果配置被写入了错误的文件（如 macOS 上写入了 .bashrc 而不是 .zshrc），使用修复脚本：
   

```bash
   # 运行配置修复脚本
   chmod +x fix_shell_config.sh
   ./fix_shell_config.sh
   ```

3. **JDK 配置问题**：
   

```bash
   # 检查 JAVA_HOME
   echo $JAVA_HOME
   
   # 重新配置 Flutter JDK
   flutter config --jdk-dir="$JAVA_HOME"
   ```

4. **权限问题**：
   

```bash
   # 确保脚本有执行权限
   chmod +x setup_flutter_env.sh
   chmod +x fix_shell_config.sh
   ```

5. **手动验证和修复**：
   

```bash
   # 检查 Flutter 路径
   ls ~/Documents/flutter/bin/flutter
   
   # 手动添加到 PATH (临时)
   export PATH="$HOME/Documents/flutter/bin:$PATH"
   
   # 验证
   flutter --version
   ```

#### 🛠️ 配置修复工具

如果遇到 Shell 配置文件问题（特别是 macOS 用户），我们还提供了专门的修复脚本：

**修复脚本功能** ( `fix_shell_config.sh` )：
* 🔍 自动检测当前 Shell 类型 (Zsh/Bash)
* 📁 识别正确的配置文件位置
* 🔄 从错误的配置文件迁移 Flutter 配置
* 🧹 可选择清理错误文件中的重复配置
* ✅ 自动验证修复结果

**使用场景**：
* macOS 用户发现配置被写入 `.bashrc` 而不是 `.zshrc`
* Linux 用户发现配置被写入错误的 Shell 配置文件
* Flutter 命令在脚本执行后仍然不可用

**使用方法**：

```bash
chmod +x fix_shell_config.sh
./fix_shell_config.sh
```

通过这些工具，您可以在几分钟内完成整个 Flutter 开发环境的搭建，即使遇到配置问题也能快速修复，无需手动处理复杂的环境变量配置。

5. `gradle下载失败
[  +65 ms] Downloading https://services.gradle.org/distributions/gradle-8.9-all.zip
[  +69 ms] Exception in thread "main" java.net. ConnectException: Connection refused
`
需要查看 `~/.gradle` 文件夹下的 `gradle.properties` 是否设置代理，如果有删除。
https://github.com/flutter/flutter/issues/33389#issuecomment-496154938
