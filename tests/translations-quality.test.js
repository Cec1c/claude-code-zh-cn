const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const repoRoot = path.resolve(__dirname, "..");

function loadTranslations() {
  return JSON.parse(
    fs.readFileSync(path.join(repoRoot, "cli-translations.json"), "utf8")
  );
}

function translationMap() {
  return new Map(loadTranslations().map((entry) => [entry.en, entry.zh]));
}

test("high-visibility translations use the curated wording", () => {
  const map = translationMap();
  const expected = new Map([
    ["/btw for side question", "/btw 题外问题"],
    ["Ask a quick side question without interrupting the main conversation", "提一个题外问题，不打断主对话"],
    ["Use /btw to ask a quick side question without interrupting Claude's current work", "用 /btw 提一个题外问题，不打断 Claude 当前工作"],
    ["Do you want to use this API key?", "要使用此 API 密钥吗？"],
    ["Allowed Unix Sockets:", "允许的 Unix domain socket："],
    ["Cannot block unix domain sockets (see Dependencies tab)", "无法阻止 Unix domain socket（参见依赖标签页）"],
    ["Manage marketplaces", "管理插件市场"],
    ["Select marketplace", "选择插件市场"],
    ["Update marketplace", "更新插件市场"],
    ["Updating marketplace…", "正在更新插件市场…"],
    ["Remove marketplace", "移除插件市场"],
    ["Sandbox is not enabled", "沙盒未启用"],
    ["Sandbox is not enabled. Enable sandbox to configure override settings.", "沙盒未启用。启用沙盒后才能配置覆盖设置。"],
    ["Enter to apply", "按 Enter 应用"],
    ["Enter to confirm · Esc to cancel", "按 Enter 确认 · 按 Esc 取消"],
    ["Enter to confirm · Esc to skip", "按 Enter 确认 · 按 Esc 跳过"],
    ["Enter to continue", "按 Enter 继续"],
    ["Enter to select ·", "按 Enter 选择 ·"],
  ]);

  for (const [en, zh] of expected) {
    assert.equal(map.get(en), zh, `translation drift for: ${en}`);
  }
});

test("translations avoid legacy half-translated phrasing for key UX terms", () => {
  const disallowedPatterns = [
    /旁路问题/,
    /插个问题/,
    /Sandbox 未启用/,
    /沙箱未启用/,
    /Unix Socket/,
    /unix domain socket/,
    /API key/,
    /管理 marketplace/,
    /选择 marketplace/,
    /更新 marketplace/,
    /正在更新 marketplace/,
    /(?<!按 )Enter 查看/,
    /(?<!按 )Enter 继续/,
    /(?<!按 )Enter 确认/,
    /(?<!按 )Enter 选择/,
    /(?<!按 )Enter 应用/,
  ];

  const allowlist = new Set([" · ./path/to/marketplace"]);

  for (const entry of loadTranslations()) {
    for (const pattern of disallowedPatterns) {
      if (!pattern.test(entry.zh)) continue;
      if (allowlist.has(entry.zh)) continue;
      assert.fail(`disallowed translation pattern "${pattern}" found in zh="${entry.zh}"`);
    }
  }
});

test("translations do not leave raw marketplace wording in Chinese text", () => {
  const allowlist = new Set([" · ./path/to/marketplace"]);

  for (const entry of loadTranslations()) {
    if (!entry.zh.includes("marketplace")) continue;
    if (allowlist.has(entry.zh)) continue;
    assert.fail(`raw marketplace wording leaked into zh="${entry.zh}"`);
  }
});
