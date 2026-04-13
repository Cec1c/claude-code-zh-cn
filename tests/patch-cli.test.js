const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const repoRoot = path.resolve(__dirname, "..");
const patchCli = path.join(repoRoot, "patch-cli.js");
const translations = path.join(repoRoot, "cli-translations.json");

test("duration patch removes English 'for' from generic Worked/Idle variants", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "cczh-patch-"));
  const cliFile = path.join(dir, "cli.js");
  fs.writeFileSync(
    cliFile,
    [
      "let teammate=`${verb} Worked for ${fmt(Date.now()-task.startTime)}`;",
      "let guarded=H&&`${A} for ${X}`;",
      'let idleA=createElement(T,{dimColor:!0},label," for ",duration);',
      'let idleB=createElement(T,{dimColor:!0},"Idle for ",idleDuration);',
      "",
    ].join("\n")
  );

  execFileSync("node", [patchCli, cliFile, translations], { encoding: "utf8" });
  const patched = fs.readFileSync(cliFile, "utf8");

  assert.equal(patched.includes("Worked for"), false, patched);
  assert.equal(patched.includes('" for "'), false, patched);
  assert.equal(patched.includes("Idle for "), false, patched);
  assert.equal(patched.includes("&&`${A} for ${X}`"), false, patched);
  assert.match(patched, /\$\{verb\}\s+\$\{fmt\(Date\.now\(\)-task\.startTime\)\}/);
  assert.match(patched, /&&`\$\{A\} \$\{X\}`/);
  assert.match(patched, /"空闲 "/);
});

test("string translation must not rewrite identifiers or object keys across code boundaries", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "cczh-patch-"));
  const cliFile = path.join(dir, "cli.js");
  fs.writeFileSync(
    cliFile,
    [
      'const modes={external:"acceptEdits"},bypassPermissions:{title:"Bypass Permissions",shortTitle:"Bypass"};',
      'const permsLabel="Permissions:";',
      'const sandboxNote="Sandbox";',
      'const autoAllowBashIfSandboxed=true;',
      'const config=h.object({failIfUnavailable:h.boolean().optional().describe("Exit with a hard gate."),autoAllowBashIfSandboxed:h.boolean().optional(),allowUnsandboxedCommands:h.boolean().optional().describe("Allow commands in the Sandbox")});',
      "",
    ].join("\n")
  );

  execFileSync("node", [patchCli, cliFile, translations], { encoding: "utf8" });
  const patched = fs.readFileSync(cliFile, "utf8");

  assert.match(patched, /const permsLabel="权限：";/);
  assert.match(patched, /const sandboxNote="沙盒";/);
  assert.match(patched, /bypassPermissions:\{title:"跳过权限检查"/, patched);
  assert.match(patched, /autoAllowBashIfSandboxed=true;/, patched);
  assert.equal(patched.includes("bypass权限：{"), false, patched);
  assert.equal(patched.includes("autoAllowBashIf沙盒ed"), false, patched);
});
