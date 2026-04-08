const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const repoRoot = path.resolve(__dirname, "..");
const hookPath = path.join(repoRoot, "plugin", "hooks", "session-start");

test("session-start re-patches when plugin changed even if Claude Code version is unchanged", () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "cczh-hook-"));
  const pluginRoot = path.join(tmp, "plugin");
  const fakeBin = path.join(tmp, "bin");
  const cliFile = path.join(tmp, "lib", "node_modules", "@anthropic-ai", "claude-code", "cli.js");
  const invokedFile = path.join(tmp, "patch-invoked");

  fs.mkdirSync(pluginRoot, { recursive: true });
  fs.mkdirSync(fakeBin, { recursive: true });
  fs.mkdirSync(path.dirname(cliFile), { recursive: true });

  fs.writeFileSync(cliFile, "#!/usr/bin/env node\n// Version: 2.1.96\n");
  fs.writeFileSync(path.join(fakeBin, "claude"), "#!/usr/bin/env bash\n");
  fs.chmodSync(path.join(fakeBin, "claude"), 0o755);

  fs.writeFileSync(
    path.join(pluginRoot, "patch-cli.sh"),
    `#!/usr/bin/env bash
set -euo pipefail
printf '1'
printf 'invoked' > ${JSON.stringify(invokedFile)}
`
  );
  fs.chmodSync(path.join(pluginRoot, "patch-cli.sh"), 0o755);
  fs.writeFileSync(path.join(pluginRoot, "manifest.json"), JSON.stringify({ version: "2.0.1" }));
  fs.writeFileSync(path.join(pluginRoot, "patch-cli.js"), "console.log('patch');\n");
  fs.writeFileSync(path.join(pluginRoot, "cli-translations.json"), "[]\n");
  fs.writeFileSync(path.join(pluginRoot, ".patched-version"), "2.1.96");

  const result = spawnSync("bash", [hookPath], {
    cwd: repoRoot,
    env: {
      ...process.env,
      CLAUDE_PLUGIN_ROOT: pluginRoot,
      PATH: `${fakeBin}:${process.env.PATH}`,
    },
    input: "\n",
    encoding: "utf8",
  });

  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.equal(fs.existsSync(invokedFile), true, "hook did not trigger re-patch for same Claude Code version");
});
