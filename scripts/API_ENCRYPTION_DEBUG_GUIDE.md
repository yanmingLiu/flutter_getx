# API 加密与混淆手动验证指南

本指南用于在 Flutter Debug 构建中验证 API 加密和接口字段混淆。

## 前置条件

确认 `lib/tools/config_tool.dart` 中：

```dart
final bool isDebug = false;
```

同时确认 `baseUrl` 指向支持加密协议的服务器。仅关闭 `isDebug`，但继续访问不支持加密的开发服务器，接口会请求失败。

传输加密只作用于 `ApiService`。独立 Dio、事件上报、图片和文件下载不会进入 AES 加密流程。

## 1. 准备依赖

在项目根目录执行：

```bash
cd /Users/ai3/Documents/siren
flutter pub get
```

## 2. 预检混淆配置

先检查 API 和字段映射，不修改源码：

```bash
dart run scripts/obfuscate_api_data.dart --check
```

命令会对 JSON 中已配置的路径执行混淆。若提示 `Ignored unmapped API path segments`，表示发现了未配置的新路径；该路径会原样保留，不会阻断构建。确认需要混淆时，再补充服务端映射或将确认不混淆的路径加入：

```text
scripts/config/api_allowlist.json
```

## 3. 备份源码

`--apply` 会直接修改 `lib` 下的 API path 和 JSON 字段。执行前必须备份：

```bash
BACKUP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/siren-api-test.XXXXXX")
cp -R lib "$BACKUP_DIR/lib"
echo "Backup: $BACKUP_DIR"
```

保留终端输出的备份目录。测试期间不要修改 `lib` 下的源码，否则恢复时这些修改会丢失。

## 4. 执行混淆

```bash
dart run scripts/obfuscate_api_data.dart --apply
```

再次检查：

```bash
dart run scripts/obfuscate_api_data.dart --check
```

混淆已经完成时，两类 replacement 数量都应为 `0`。

检查混淆后的代码：

```bash
flutter analyze lib
```

## 5. 运行 Debug 应用

查看设备：

```bash
flutter devices
```

运行到指定设备：

```bash
flutter run -d <device-id>
```

只有一台可用设备时，也可以直接执行：

```bash
flutter run
```

虽然这里运行的是 Debug 构建，但因为 `ConfigTool.isDebug` 为 `false`，通过 `ApiService` 发出的请求会执行以下处理：

- 加密完整 API path 和 query。
- 加密普通 JSON 请求体；请求 body/query 的字段名保持原协议。
- 加密真实 device id。
- 使用混淆后的 Header 名。
- 解密并解析服务器响应。

修改混淆文件后不要只依赖 hot reload，应停止旧进程并重新执行 `flutter run`。

## 6. 恢复源码

退出 `flutter run` 后，可以使用映射表还原 API path 和模型字段：

```bash
dart run scripts/obfuscate_api_data.dart --restore
dart format lib
```

还原操作是幂等的，可以重复执行。也可以只还原其中一类：

```bash
dart run scripts/obfuscate_api.dart --restore
dart run scripts/obfuscate_model.dart --restore
```

仍建议保留第 3 步创建的完整备份。需要精确恢复到混淆前的全部文件内容时，使用备份：

```bash
rm -rf lib
cp -R "$BACKUP_DIR/lib" lib
rm -rf "$BACKUP_DIR"

flutter pub get
dart run scripts/obfuscate_api_data.dart --check
```

恢复后，`--check` 应重新显示待替换数量，例如：

```text
Checked API path obfuscation: 176 replacement(s)
Checked model field obfuscation: 746 replacement(s) in 38 file(s)
```

实际数量可能随接口和模型调整而变化。

不要通过再次执行 `--apply` 尝试恢复源码；应使用 `--restore`。

## 7. 只运行自动化测试

验证 AES 算法：

```bash
flutter test test/api_cipher_test.dart
```

验证混淆脚本可重复执行：

```bash
bash test/obfuscation_scripts_test.sh
```

打包脚本会保留 `lib` 下的生成和混淆变更，便于手动对比和恢复。如果 API
或 Model 目标源文件尚未创建，脚本会输出警告并继续打包。

运行全部 Flutter 测试：

```bash
flutter test
```

## 8. 常见问题

### 所有接口都失败

检查：

1. `isDebug` 是否为 `false`。
2. `baseUrl` 是否为支持当前 Key、IV 和混淆映射的服务器。
3. 服务端是否使用相同的 AES Key、IV 和 URL 包装前缀。
4. 是否已执行 `--apply`。

### 返回 `Encrypted response decode failed`

说明服务器响应不是预期的 AES hex，或者客户端与服务端的 Key/IV 不一致。也需要确认非 2xx 错误响应是否同样经过加密。

### `--check` 报未映射路径

不能直接忽略。应先确认服务端是否提供对应混淆值：

- 有服务端映射：补充 `scripts/config/api_map.json`。
- 服务端明确要求保留原 path segment：补充 `scripts/config/api_allowlist.json`。

### 测试时修改了源码

不要直接执行恢复命令，否则会覆盖测试期间的修改。先单独保存这些修改，再恢复备份。
