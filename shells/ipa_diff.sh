#!/bin/bash

# =================================================================
# Flutter IPA 4.3 风险诊断专家系统 (终端日志 + Markdown 同步版)
# =================================================================

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# 1. 检查并安装依赖
install_deps() {
    echo -e "赋予权限：在终端执行 chmod +x ipa_diff.sh 运行脚本：./ipa_diff.sh v1.ipa v2.ipa"
    echo -e "${BLUE}--- [1/5] 检查环境依赖... ---${NC}"
    if ! command -v brew &> /dev/null; then
        echo "未发现 Homebrew，请先安装 Homebrew。"
        exit 1
    fi
    for cmd in bloaty md5sum bc; do
        if ! command -v $cmd &> /dev/null; then
            echo "正在安装 $cmd..."
            brew install ${cmd/md5sum/coreutils}
        fi
    done
}

# 风险判定等级 (用于文本)
get_risk_text() {
    local val=$1
    if (( $(echo "$val > 70" | bc -l) )); then echo "🔴 高风险 (High)";
    elif (( $(echo "$val > 40" | bc -l) )); then echo "🟡 中风险 (Medium)";
    else echo "🟢 低风险 (Low)"; fi
}

# 参数校验
if [[ $# -lt 2 ]]; then
    echo -e "${RED}用法: $0 <old.ipa> <new.ipa>${NC}"
    exit 1
fi

IPA1=$1; IPA2=$2
TIME_STAMP=$(date +%Y%m%d_%H%M%S)
WORKDIR="diag_$TIME_STAMP"
REPORT_FILE="$WORKDIR/Diagnostic_Report.md"

# 执行准备
install_deps
mkdir -p "$WORKDIR/app1" "$WORKDIR/app2"

echo -e "${BLUE}--- [2/5] 正在解压并定位二进制文件... ---${NC}"
unzip -q "$IPA1" -d "$WORKDIR/app1"
unzip -q "$IPA2" -d "$WORKDIR/app2"

# 定位关键文件
BIN1=$(find "$WORKDIR/app1" -name "App" -path "*/App.framework/App" | head -n 1)
BIN2=$(find "$WORKDIR/app2" -name "App" -path "*/App.framework/App" | head -n 1)
ASSET1=$(find "$WORKDIR/app1" -name "flutter_assets" -type d | head -n 1)
ASSET2=$(find "$WORKDIR/app2" -name "flutter_assets" -type d | head -n 1)

if [[ -z "$BIN1" || -z "$BIN2" ]]; then
    echo -e "${RED}错误: 无法在 IPA 中找到 App.framework/App 二进制文件。${NC}"
    exit 1
fi

# 3. 提取数据
echo -e "${BLUE}--- [3/5] 提取特征指纹并计算... ---${NC}"

# 字符串对比
strings "$BIN1" | sort | uniq > "$WORKDIR/s1.txt"
strings "$BIN2" | sort | uniq > "$WORKDIR/s2.txt"
TOTAL_S=$(wc -l < "$WORKDIR/s1.txt")
COMMON_S=$(comm -12 "$WORKDIR/s1.txt" "$WORKDIR/s2.txt" | wc -l)
S_PERCENT=$(echo "scale=2; $COMMON_S * 100 / $TOTAL_S" | bc)

# 符号对比
nm -pa "$BIN1" | awk '{print $3}' | sort | uniq > "$WORKDIR/sym1.txt"
nm -pa "$BIN2" | awk '{print $3}' | sort | uniq > "$WORKDIR/sym2.txt"
TOTAL_SYM=$(wc -l < "$WORKDIR/sym1.txt")
COMMON_SYM=$(comm -12 "$WORKDIR/sym1.txt" "$WORKDIR/sym2.txt" | wc -l)
if [ "$TOTAL_SYM" -gt 0 ]; then
    SYM_PERCENT=$(echo "scale=2; $COMMON_SYM * 100 / $TOTAL_SYM" | bc)
else
    SYM_PERCENT=0
fi

# 资源对比
TOTAL_AS=0; COMMON_AS=0; AS_PERCENT=0
if [[ -d "$ASSET1" && -d "$ASSET2" ]]; then
    find "$ASSET1" -type f -exec md5sum {} + | awk -F/ '{print $NF}' | sort > "$WORKDIR/as1.txt"
    find "$ASSET2" -type f -exec md5sum {} + | awk -F/ '{print $NF}' | sort > "$WORKDIR/as2.txt"
    TOTAL_AS=$(wc -l < "$WORKDIR/as1.txt")
    COMMON_AS=$(comm -12 "$WORKDIR/as1.txt" "$WORKDIR/as2.txt" | wc -l)
    AS_PERCENT=$(echo "scale=2; $COMMON_AS * 100 / $TOTAL_AS" | bc)
fi

# 4. 实时输出日志到屏幕
echo -e "\n${BOLD}${CYAN}================================================================${NC}"
echo -e "           ${BOLD}Flutter IPA 相似度诊断报告 (Apple 4.3 预警)${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}"

echo -e "\n${BOLD}[指标对比表]${NC}"
printf "| %-18s | %-10s | %-10s | %-12s |\n" "检测项目" "总量" "重复" "相似度"
echo "----------------------------------------------------------------"
printf "| %-18s | %-10d | %-10d | ${YELLOW}%-10s%%${NC} |\n" "Strings(业务文本)" "$TOTAL_S" "$COMMON_S" "$S_PERCENT"
printf "| %-18s | %-10d | %-10d | ${RED}%-10s%%${NC} |\n" "Symbols(函数符号)" "$TOTAL_SYM" "$COMMON_SYM" "$SYM_PERCENT"
printf "| %-18s | %-10d | %-10d | ${GREEN}%-10s%%${NC} |\n" "Assets(资源指纹)" "$TOTAL_AS" "$COMMON_AS" "$AS_PERCENT"
echo "----------------------------------------------------------------"

echo -e "\n${BOLD}[风险评估总结]${NC}"
echo -e "   1. 静态代码扫描风险: $(get_risk_text $S_PERCENT)"
echo -e "   2. 原生插件重合风险: $(get_risk_text $SYM_PERCENT)"
echo -e "   3. 资源文件重合风险: $(get_risk_text $AS_PERCENT)"

echo -e "\n${BOLD}[二进制结构差异分析 (Bloaty)]${NC}"
echo -e "${PURPLE}----------------------------------------------------------------${NC}"
BLOATY_OUT=$(bloaty "$BIN2" -- "$BIN1" -d sections | grep -E "TOTAL|__TEXT|__DATA")
echo "$BLOATY_OUT"
echo -e "${PURPLE}----------------------------------------------------------------${NC}"

# 5. 同时生成 Markdown 报告文件
{
    echo "# IPA 相似度诊断报告 (Apple 4.3 风险评估)"
    echo "生成时间: $(date)"
    echo -e "\n## 1. 核心风险概览"
    echo "| 检测项目 | 总量 | 重复量 | 相似度 | 风险等级 |"
    echo "| :--- | :--- | :--- | :--- | :--- |"
    echo "| 业务字符串 (Strings) | $TOTAL_S | $COMMON_S | $S_PERCENT% | $(get_risk_text $S_PERCENT) |"
    echo "| 函数符号 (Symbols) | $TOTAL_SYM | $COMMON_SYM | $SYM_PERCENT% | $(get_risk_text $SYM_PERCENT) |"
    echo "| 资源指纹 (Assets) | $TOTAL_AS | $COMMON_AS | $AS_PERCENT% | $(get_risk_text $AS_PERCENT) |"

    echo -e "\n## 2. 二进制结构差异 (Bloaty Snapshots)"
    echo '```text'
    echo "$BLOATY_OUT"
    echo '```'

    echo -e "\n## 3. 详细 Action Plan (改进建议)"
    if (( $(echo "$S_PERCENT > 55" | bc -l) )); then 
        echo "- [ ] **必须开启混淆**: 当前字符串重合度 $S_PERCENT% 偏高，请检查是否使用了 \`--obfuscate\`。"; 
    fi
    if (( $(echo "$SYM_PERCENT > 80" | bc -l) )); then 
        echo "- [ ] **修改 Native 符号**: 符号重合度极高，建议在 iOS 原生部分增加一些无意义的类或分类。"; 
    fi
    echo "- [ ] **结构偏移**: 改变代码布局，目标使 \`__TEXT\` 段差异率提升至 10% 以上。"
} > "$REPORT_FILE"

echo -e "\n${GREEN}${BOLD}--- [5/5] 诊断完成！ ---${NC}"
echo -e "Markdown 详细报告已生成: ${CYAN}${BOLD}$REPORT_FILE${NC}"
echo -e "${BOLD}${CYAN}================================================================${NC}\n"