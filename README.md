<div align="center">

# claude-code-zh-cn

**Claude Code 简体中文本地化插件**

让终端里的 AI 编程助手说中文 🇨🇳

[![GitHub](https://img.shields.io/badge/GitHub-taekchef%2Fclaude--code--zh--cn-blue?logo=github)](https://github.com/taekchef/claude-code-zh-cn)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-%E2%89%A52.1.x-green)](https://github.com/anthropics/claude-code)

</div>

---

## 它做了什么？

Claude Code 的界面文字全部硬编码在英文里。这个插件通过**内置设置 + Hook 系统 + 插件机制**，在不修改源码的前提下，把大部分用户可见文字换成中文。

## 效果一览

### Spinner 动词（188 个趣味翻译）

等待 Claude 工作时，原来显示的英文动词变成了：

```
光合作用中...  蹦迪中...  太空步中...  克劳丁中...
搞事情中...  七荤八素中...  那个啥来着中...  摸鱼中...
```

每个翻译都保留了原版英文的趣味灵魂：

| 英文 | 中文 | 英文 | 中文 |
|------|------|------|------|
| `Thinking` | 思考中 | `Moonwalking` | 太空步中 |
| `Photosynthesizing` | 光合作用中 | `Flibbertigibbeting` | 叽里呱啦中 |
| `Discombobulating` | 七荤八素中 | `Whatchamacalliting` | 那个啥来着中 |
| `Shenaniganing` | 搞事情中 | `Razzmatazzing` | 花里胡哨中 |
| `Boondoggling` | 瞎忙活中 | `Prestidigitating` | 变魔术中 |
| `Clauding` | 克劳丁中 | `Boogieing` | 蹦迪中 |
| `Canoodling` | 腻歪中 | `Spelunking` | 探洞中 |

### Spinner 提示（41 条中文提示）

等待时随机显示的 "Tip:" 提示全部汉化：

> 💡 按 Shift+Tab 在默认模式、自动接受编辑模式和 Plan 模式之间切换
>
> 💡 你知道可以直接把图片文件拖拽到终端里吗？
>
> 💡 使用 /effort high 获得更好的一次性回答。Claude 会先深思熟虑

### AI 回复自动中文

通过 `language: Chinese` 设置 + SessionStart Hook 注入中文上下文，AI 默认用中文回复，技术术语保留英文。

### 通知翻译

常见系统通知自动附带中文说明：

| 原始通知 | 中文翻译 |
|---------|---------|
| Rate limited | 请求频率受限，请稍后再试 |
| Token limit reached | Token 用量已达上限 |
| Context window approaching | 上下文窗口即将用尽，建议使用 /compact 压缩 |

## 覆盖范围

| 功能 | 状态 | 覆盖方式 |
|------|------|---------|
| AI 回复语言 | ✅ 已覆盖 | `language` 设置 |
| Spinner 动词 | ✅ 已覆盖 | `spinnerVerbs` 设置（188 个） |
| Spinner 提示 | ✅ 已覆盖 | `spinnerTipsOverride` 设置（41 条） |
| 会话中文上下文 | ✅ 已覆盖 | SessionStart Hook |
| 通知翻译 | ✅ 已覆盖 | Notification Hook |
| 输出风格 | ✅ 已覆盖 | Chinese Output Style |
| 权限对话框 | ❌ 未覆盖 | 硬编码 UI，需上游支持 |
| /help 输出 | ❌ 未覆盖 | 硬编码 UI，需上游支持 |
| 设置菜单 | ❌ 未覆盖 | 硬编码 UI，需上游支持 |
| Moth 伴生文字 | ❌ 未覆盖 | 硬编码 UI，需上游支持 |

## 快速开始

### 安装

```bash
git clone https://github.com/taekchef/claude-code-zh-cn.git
cd claude-code-zh-cn
./install.sh
```

安装脚本会自动：
- 备份现有 `~/.claude/settings.json`
- 合并中文设置到 settings.json
- 安装插件到 `~/.claude/plugins/claude-code-zh-cn/`

### 前置要求

- Claude Code CLI >= 2.1.x
- Python 3
- 可选：jq（更精准的 JSON 合并）

### 验证

重启 Claude Code 后，发送任意请求。如果看到 spinner 显示"思考中"、"光合作用中"等中文，说明生效了。

### 卸载

```bash
cd claude-code-zh-cn
./uninstall.sh
```

自动恢复原始 settings.json 并移除插件。

## 项目结构

```
claude-code-zh-cn/
├── README.md                ← 你在这里
├── LICENSE                  ← MIT
├── install.sh               ← 一键安装
├── uninstall.sh             ← 一键卸载
├── settings-overlay.json    ← 合并到 settings.json 的中文设置
├── plugin/
│   ├── manifest.json        ← 插件清单
│   ├── hooks.json           ← Hook 事件配置
│   ├── hooks/
│   │   ├── session-start    ← 注入中文上下文
│   │   └── notification     ← 通知翻译
│   └── output-styles/
│       └── chinese.json     ← 中文输出风格
├── tips/
│   ├── en.json              ← 英文原文（对照）
│   └── zh-CN.json           ← 中文翻译
└── verbs/
    └── zh-CN.json           ← 188 个中文动词
```

## 技术原理

Claude Code CLI 是一个 13MB 的单文件压缩包（`cli.js`），所有 UI 文字硬编码其中，没有 i18n 基础设施。本项目不修改源码，而是利用 Claude Code 自带的三层扩展点：

**Layer 1 — 内置设置**
- `language`: 控制 AI 回复语言
- `spinnerTipsOverride`: 替换等待提示文字
- `spinnerVerbs`: 替换 spinner 动词

**Layer 2 — Hook 系统**
- `SessionStart`: 会话启动时注入中文上下文指令
- `Notification`: 拦截系统通知并翻译

**Layer 3 — 插件系统**
- 标准 Claude Code 插件格式
- 提供 Chinese Output Style
- 可通过 `install.sh` / `uninstall.sh` 管理生命周期

## 自定义

想调整翻译？直接编辑对应的 JSON 文件：

```bash
# 编辑 spinner 提示
vim tips/zh-CN.json

# 编辑 spinner 动词
vim verbs/zh-CN.json
```

编辑完后重新运行 `./install.sh` 即可生效。

## 贡献

欢迎 PR！

- 翻译改进 → 编辑 `tips/zh-CN.json` 或 `verbs/zh-CN.json`
- 新功能 → 添加 hook 或 output style
- Bug → 提 [Issue](https://github.com/taekchef/claude-code-zh-cn/issues)

## 许可证

[MIT](./LICENSE)

## 致谢

- UI 字符串提取自 [Claude Code](https://github.com/anthropics/claude-code) v2.1.90
- 灵感来自 `zstings/claude-code-zh-cn` VS Code 扩展

---

*本项目不是 Anthropic 官方产品。Claude Code 是 Anthropic Inc. 的商标。*
