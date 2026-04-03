#!/usr/bin/env bash
# claude-code-zh-cn 安装脚本
# 将中文本地化设置合并到 Claude Code 的 settings.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"
BACKUP_FILE="$HOME/.claude/settings.json.zh-cn-backup.$(date +%Y%m%d%H%M%S)"
OVERLAY_FILE="$SCRIPT_DIR/settings-overlay.json"
PLUGIN_SRC="$SCRIPT_DIR/plugin"
PLUGIN_DST="$HOME/.claude/plugins/claude-code-zh-cn"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Claude Code 中文本地化插件 安装 ===${NC}"
echo ""

# 检查依赖
if ! command -v node &>/dev/null; then
    echo -e "${RED}错误：需要 node，请先安装${NC}"
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo -e "${RED}错误：需要 python3，请先安装${NC}"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo -e "${YELLOW}提示：建议安装 jq 以获得更好的 JSON 合并支持${NC}"
    echo "  brew install jq"
    USE_JQ=false
else
    USE_JQ=true
fi

# 检查 settings.json 是否存在
if [ ! -f "$SETTINGS_FILE" ]; then
    echo -e "${YELLOW}settings.json 不存在，创建新文件${NC}"
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    echo '{}' > "$SETTINGS_FILE"
fi

# 备份
cp "$SETTINGS_FILE" "$BACKUP_FILE"
echo -e "${GREEN}已备份 settings.json → ${BACKUP_FILE}${NC}"

# 读取 overlay
OVERLAY_CONTENT=$(cat "$OVERLAY_FILE")

# 合并 settings
if $USE_JQ; then
    # 使用 jq 深度合并
    MERGED=$(jq -s '.[0] * .[1]' "$SETTINGS_FILE" <(echo "$OVERLAY_CONTENT"))
    echo "$MERGED" > "$SETTINGS_FILE"
else
    # 使用 python3 合并（通过环境变量传参，避免注入风险）
    ZH_CN_SETTINGS="$SETTINGS_FILE" ZH_CN_OVERLAY="$OVERLAY_CONTENT" python3 -c "
import json, sys, os

settings_file = os.environ['ZH_CN_SETTINGS']
overlay_content = os.environ['ZH_CN_OVERLAY']

with open(settings_file, 'r') as f:
    settings = json.load(f)

overlay = json.loads(overlay_content)

# Deep merge - overlay takes precedence
def deep_merge(base, override):
    result = base.copy()
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result

merged = deep_merge(settings, overlay)

with open(settings_file, 'w') as f:
    json.dump(merged, f, indent=2, ensure_ascii=False)
    f.write('\n')
" 2>/dev/null
fi

echo -e "${GREEN}已更新 settings.json${NC}"

# 安装插件
mkdir -p "$PLUGIN_DST"
cp -r "$PLUGIN_SRC"/* "$PLUGIN_DST/"
echo -e "${GREEN}已安装插件 → ${PLUGIN_DST}${NC}"

# Patch cli.js 硬编码文字
CLI_FILE="$(dirname "$(which claude)")/../lib/node_modules/@anthropic-ai/claude-code/cli.js" 2>/dev/null || true
if [ -z "$CLI_FILE" ]; then
    # 尝试 npm global 路径
    CLI_FILE="$(npm root -g)/@anthropic-ai/claude-code/cli.js"
fi

if [ -f "$CLI_FILE" ]; then
    echo ""
    echo -e "${BLUE}正在 patch cli.js 硬编码文字...${NC}"

    # 如果已有备份，先恢复原始文件再重新 patch（确保幂等）
    if [ -f "${CLI_FILE}.zh-cn-backup" ]; then
        cp "${CLI_FILE}.zh-cn-backup" "$CLI_FILE"
        echo -e "${GREEN}已从备份恢复原始 cli.js${NC}"
    else
        # 首次安装，备份原始文件
        cp "$CLI_FILE" "${CLI_FILE}.zh-cn-backup"
        echo -e "${GREEN}已备份 cli.js${NC}"
    fi

    # 用 node 统一处理所有 patch（基于内容匹配，不依赖变量名，跨版本稳定）
    PATCH_COUNT=$(node -e '
const fs = require("fs");
const f = process.argv[1];
let s = fs.readFileSync(f, "utf8");
let count = 0;

function tryReplace(from, to) {
    if (s.includes(from)) {
        s = s.split(from).join(to);
        count++;
        return true;
    }
    return false;
}

// 1. 过去式动词（直接用 UTF-8 字符，不用 String.raw 避免 \u 转义问题）
tryReplace(
    `["Baked","Brewed","Churned","Cogitated","Cooked","Crunched","Saut\u00e9ed","Worked"]`,
    `["烘焙了","沏了","翻搅了","琢磨了","烹饪了","嚼了","翻炒了","忙活了"]`
);

// 2. /btw 提示（用 Unicode 转义避免 bash 单引号问题）
tryReplace(
    "Use /btw to ask a quick side question without interrupting Claude\u0027s current work",
    "\u4f7f\u7528 /btw \u63d0\u4e00\u4e2a\u5feb\u901f\u95ee\u9898\uff0c\u4e0d\u4f1a\u6253\u65ad\u5f53\u524d\u5de5\u4f5c"
);

// 3. /clear 提示
tryReplace(
    "Use /clear to start fresh when switching topics and free up context",
    "\u4f7f\u7528 /clear \u6e05\u7a7a\u5bf9\u8bdd\uff0c\u5207\u6362\u8bdd\u9898\u5e76\u91ca\u653e\u4e0a\u4e0b\u6587"
);

// 4. Tip: 前缀（匹配 Tip: ${任意变量}）
const tipMatch = s.match(/\x60Tip: \$\{[^}]+\}\x60/);
if (tipMatch) {
    const replaced = tipMatch[0].replace("Tip: ", "\u{1F4A1} ");
    s = s.split(tipMatch[0]).join(replaced);
    count++;
}

// 5. recap: 和 nudge/nudges — v2.1.91+ 已移除，跳过

// 6. 去掉耗时 " Worked for " / " for " 连接符
if (!tryReplace(" Worked for ", " ")) {
    tryReplace(" for ", " ");
}

// 8. 时间单位中文化（通过特征定位 duration formatter 函数）
const marker = "if(q<60000)";
const markerIdx = s.indexOf(marker);
if (markerIdx !== -1) {
    const fnStart = s.lastIndexOf("function", markerIdx);
    if (fnStart !== -1) {
        let depth = 0, fnEnd = -1;
        for (let i = s.indexOf("{", fnStart); i < s.length; i++) {
            if (s[i] === "{") depth++;
            else if (s[i] === "}") depth--;
            if (depth === 0) { fnEnd = i; break; }
        }
        if (fnEnd !== -1) {
            let fn = s.substring(fnStart, fnEnd + 1);
            const pairs = [
                ["}d ${z}h ${Y}m ${$}s", "}\u5929${z}\u65f6${Y}\u5206${$}\u79d2"],
                ["}d ${z}h ${Y}m", "}\u5929${z}\u65f6${Y}\u5206"],
                ["}h ${Y}m ${$}s", "}\u65f6${Y}\u5206${$}\u79d2"],
                ["}d ${z}h", "}\u5929${z}\u65f6"],
                ["}h ${Y}m", "}\u65f6${Y}\u5206"],
                ["}m ${$}s", "}\u5206${$}\u79d2"],
                ["}d", "}\u5929"],
                ["}h", "}\u65f6"],
                ["}m", "}\u5206"],
                ["}s", "}\u79d2"],
                ["\"0s\"", "\"0\u79d2\""],
            ];
            let changed = false;
            pairs.forEach(([from, to]) => {
                if (fn.includes(from)) {
                    fn = fn.split(from).join(to);
                    changed = true;
                }
            });
            if (changed) {
                s = s.substring(0, fnStart) + fn + s.substring(fnEnd + 1);
                count++;
            }
        }
    }
}

fs.writeFileSync(f, s);
console.log(count);
' "$CLI_FILE" 2>/dev/null)

    echo -e "${GREEN}已 patch cli.js（${PATCH_COUNT:-0} 处硬编码文字）${NC}"
else
    echo -e "${YELLOW}未找到 cli.js，跳过 patch 步骤${NC}"
    echo -e "  提示：如果 Claude Code 安装在非标准路径，可能需要手动 patch"
fi

echo ""
echo -e "${GREEN}=== 安装完成！===${NC}"
echo ""
echo -e "已启用的功能："
echo -e "  ${GREEN}✓${NC} AI 回复语言 → 中文"
echo -e "  ${GREEN}✓${NC} Spinner 提示 → 中文（41 条）"
echo -e "  ${GREEN}✓${NC} Spinner 动词 → 中文（187 个）"
echo -e "  ${GREEN}✓${NC} 会话启动 Hook → 中文上下文注入"
echo -e "  ${GREEN}✓${NC} 通知 Hook → 中文翻译"
echo -e "  ${GREEN}✓${NC} 输出风格 → Chinese"
echo -e "  ${GREEN}✓${NC} CLI Patch → 回复耗时动词 + /btw + /clear 提示中文化"
echo ""
echo -e "重启 Claude Code 即可生效。如需卸载，运行：${YELLOW}./uninstall.sh${NC}"
echo -e "${YELLOW}注意：${NC}Claude Code 更新后需重跑 ${YELLOW}./install.sh${NC} 以重新 patch cli.js"
