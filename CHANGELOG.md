# Changelog

本项目的版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)：

- **主版本号**：不兼容的架构变更（比如需要完全重写安装流程）
- **次版本号**：新增功能或显著改进（比如新增 patch、新增翻译）
- **修订号**：Bug 修复和小调整（比如修正一条翻译）

## [1.1.0] - 2026-04-03

### 新增

- Hook 运行提示中文化（5 条）：运行预压缩 Hook…、运行压缩后 Hook…、运行会话启动 Hook…、运行停止 Hook…、运行 ${event} Hook
- Hook 计数中文化（2 条）：1 个 Hook…、3 个 Hook…
- 后台代理提示中文化（1 条）：所有后台代理已停止
- /compact 压缩对话提示中文化（1 条）：压缩对话中…
- CLI Patch 总数从 7 提升至 17

### 改进

- Hook 相关术语保留英文（Hook 而非"钩子"），与 API、PR 等技术术语处理一致
- README 覆盖表新增 Hook 运行提示、Hook 计数、后台代理提示、/compact 提示

## [1.0.0] - 2026-03-29

### 首个正式版本

- AI 回复语言 → 中文（`language: Chinese`）
- 187 个趣味 Spinner 动词翻译（光合作用中、蹦迪中、搞事情中…）
- 41 条中文 Spinner 提示
- 会话启动 Hook — 中文上下文注入
- 通知 Hook — 6 条中文翻译（频率限制、Token 限额、会话过期等）
- Chinese Output Style
- CLI Patch（内容匹配，跨版本稳定）：
  - 回复耗时动词（8 个：琢磨了、忙活了、烘焙了…）
  - 时间单位中文化（天、时、分、秒）
  - 去掉耗时连接符（"Worked for" → 空格）
  - /btw 提示中文化
  - /clear 提示中文化
  - Tip 前缀 → 💡
- 自动重 patch 机制 — Claude Code 更新后首次会话自动修复
- install.sh 一键安装
- uninstall.sh 精准卸载（不丢用户配置）
- 版本校验的备份机制
