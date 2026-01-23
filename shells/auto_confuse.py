import os
import random
import string
import re

# 在项目根目录执行： python3 auto_confuse.py
# ===== 配置 =====
GEN_DIR = "./lib/generated_junk"
MAIN_DART = "./lib/main.dart"
ASSETS_DIR = "./assets"
FILE_COUNT = 100  # 生成文件数（建议100-200，足以拉开二进制差异）

def random_str(length=8):
    return ''.join(random.choices(string.ascii_lowercase, k=length))

def generate_junk_logic():
    if not os.path.exists(GEN_DIR):
        os.makedirs(GEN_DIR)
    
    print(f"🚀 [1/4] 正在生成 {FILE_COUNT} 个深度干扰文件...")
    
    class_names = []
    for i in range(FILE_COUNT):
        suffix = random_str(6).capitalize()
        class_name = f"InternalService{suffix}"
        class_names.append(class_name)
        file_path = os.path.join(GEN_DIR, f"junk_service_{i}.dart")
        
        # 生成一些具有一定复杂度的逻辑，防止被简单的编译器优化
        with open(file_path, "w") as f:
            f.write(f"""
class {class_name} {{
  final int seed = {random.randint(100, 999)};
  
  void execute() {{
    var data = List.generate(10, (i) => i + seed);
    var result = data.map((e) => e * 2).reduce((a, b) => a ^ b);
    if (DateTime.now().millisecondsSinceEpoch % 2 == 0) {{
      print("System Status: $result");
    }}
  }}

  String encrypt(String input) {{
    return input.replaceAll('e', '{random_str(2)}').split('').reversed.join();
  }}
}}
""")
    return class_names

def create_manager(class_names):
    print(f"📦 [2/4] 正在创建垃圾代码入口管理文件...")
    manager_path = os.path.join(os.path.dirname(GEN_DIR), "junk_manager.dart")
    with open(manager_path, "w") as f:
        for i in range(len(class_names)):
            f.write(f"import 'generated_junk/junk_service_{i}.dart';\n")
        
        f.write("\nclass JunkManager {\n  static void init() {\n")
        f.write("    // 动态调用防止被 Tree-shaking 优化\n")
        for name in class_names:
            f.write(f"    {name}().execute();\n")
        f.write("  }\n}\n")
    return manager_path

def inject_main():
    print(f"💉 [3/4] 正在将入口注入 main.dart...")
    if not os.path.exists(MAIN_DART):
        print("❌ 错误: 未找到 lib/main.dart")
        return

    with open(MAIN_DART, "r") as f:
        content = f.read()

    # 1. 注入 Import
    import_stmt = "import 'junk_manager.dart';\n"
    if import_stmt not in content:
        content = import_stmt + content

    # 2. 注入调用 (在 main 函数开始处)
    if "JunkManager.init()" not in content:
        # 匹配 main() { 或 main() async {
        content = re.sub(r'(main\s*\(.*?\)\s*(async)?\s*\{)', r'\1\n  JunkManager.init();', content)

    with open(MAIN_DART, "w") as f:
        f.write(content)

def obfuscate_assets():
    if not os.path.exists(ASSETS_DIR):
        print("⏭️ 跳过 [4/4]: 未发现 assets 目录")
        return
    print("🎨 [4/4] 正在批量修改资源 MD5...")
    count = 0
    for root, _, files in os.walk(ASSETS_DIR):
        for file in files:
            if file.lower().endswith(('.png', '.jpg', '.jpeg', '.json')):
                path = os.path.join(root, file)
                with open(path, "ab") as f:
                    f.write(os.urandom(8)) # 追加8字节随机混淆码
                count += 1
    print(f"✅ 已混淆 {count} 个资源文件")

if __name__ == "__main__":
    names = generate_junk_logic()
    create_manager(names)
    inject_main()
    obfuscate_assets()
    print("\n" + "="*40)
    print("✨ 混淆注入完成！现在可以进行打包：")
    print(f"{BLUE}flutter build ipa --obfuscate --split-debug-info=./symbols{NC}")
    print("="*40)