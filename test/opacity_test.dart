import 'package:flutter_test/flutter_test.dart';

/// 核心计算函数：将百分比转换为两位十六进制字符串
/// 输入: 0.5 (代表 50%)
/// 输出: "80"
String getOpacityHex(double opacity) {
  // 1. 边界检查，确保在 0.0 - 1.0 之间
  if (opacity < 0.0) opacity = 0.0;
  if (opacity > 1.0) opacity = 1.0;

  // 2. 计算 0-255 的整数值 (四舍五入)
  // 0.5 * 255 = 127.5 -> round() -> 128
  int alpha = (opacity * 255).round();

  // 3. 转换为 16 进制并补齐两位
  // 128 -> "80"
  return alpha.toRadixString(16).padLeft(2, '0').toUpperCase();
}

void main() {
  group('Hex Opacity Calculator Tests', () {
    test('', () {
      // 准备数据 // 50%
      const double inputOpacity = 0.12;

      // 执行计算
      final String result = getOpacityHex(inputOpacity);

      // 打印调试信息（运行 flutter test 时可以看到）
      print('---------------------------------------');
      print('输入: ${inputOpacity * 100}%');
      print('计算结果: $result');
      print('---------------------------------------');
    });

    test('验证其他常见透明度', () {
      // 100% -> 255 -> FF
      expect(getOpacityHex(1.0), 'FF');

      // 0% -> 0 -> 00
      expect(getOpacityHex(0.0), '00');

      // 10% -> 25.5 -> 26 -> 1A
      expect(getOpacityHex(0.1), '1A');
    });
  });
}
