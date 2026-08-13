const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const asar = require("@electron/asar");
const { getPath7za } = require("app-builder-lib/out/toolsets/7zip.js");

const launcherRoot = path.resolve(__dirname, "..");
const artifactsDirectory = path.join(launcherRoot, "artifacts");
const launcherManifest = JSON.parse(
  fs.readFileSync(path.join(launcherRoot, "package.json"), "utf8"),
);
const expectedVersion = launcherManifest.version;
const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "codex-web-gpt-package-inspect-"));

function artifact(pattern, label) {
  const matches = fs.readdirSync(artifactsDirectory)
    .filter((name) => pattern.test(name))
    .sort();
  if (matches.length !== 1) {
    throw new Error(
      `Expected exactly one ${label} in ${artifactsDirectory}; found ${matches.join(", ") || "none"}`,
    );
  }
  return path.join(artifactsDirectory, matches[0]);
}

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: scratch,
    encoding: "utf8",
    timeout: 120_000,
    windowsHide: true,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(
      `${command} failed with status ${result.status}: ${result.stderr?.trim() || result.stdout?.trim() || "no output"}`,
    );
  }
  return result.stdout.trim();
}

async function main() {
  if (process.platform !== "win32") {
    throw new Error(`Windows package inspection requires win32; got ${process.platform}/${process.arch}`);
  }

  const installer = artifact(/-win-x64\.exe$/, "Windows launcher installer");
  const sevenZip = await getPath7za();
  run(sevenZip, [
    "x",
    "-y",
    "-bd",
    "-bb0",
    `-o${scratch}`,
    installer,
    "resources\\app.asar",
    "resources\\runtime\\manifest.json",
    "resources\\runtime\\runtime\\bun.exe",
    `${launcherManifest.build.productName}.exe`,
  ]);

  const packagedApp = path.join(scratch, `${launcherManifest.build.productName}.exe`);
  const appAsar = path.join(scratch, "resources", "app.asar");
  const runtimeManifestPath = path.join(scratch, "resources", "runtime", "manifest.json");
  const runtimeBun = path.join(scratch, "resources", "runtime", "runtime", "bun.exe");
  for (const required of [packagedApp, appAsar, runtimeManifestPath, runtimeBun]) {
    if (!fs.statSync(required).isFile()) throw new Error(`Packaged file is missing: ${required}`);
  }

  const packagedManifest = JSON.parse(asar.extractFile(appAsar, "package.json").toString());
  if (packagedManifest.name !== launcherManifest.name
    || packagedManifest.version !== expectedVersion
    || packagedManifest.main !== launcherManifest.main) {
    throw new Error(`Unexpected packaged launcher manifest: ${JSON.stringify(packagedManifest)}`);
  }

  const runtimeManifest = JSON.parse(fs.readFileSync(runtimeManifestPath, "utf8"));
  if (runtimeManifest.schemaVersion !== 1
    || runtimeManifest.appVersion !== expectedVersion
    || runtimeManifest.platform !== "win32"
    || runtimeManifest.arch !== "x64"
    || !/^[a-f0-9]{64}$/.test(runtimeManifest.bundleId)
    || typeof runtimeManifest.bunRevision !== "string"
    || runtimeManifest.bunRevision.length === 0) {
    throw new Error(`Unexpected embedded runtime manifest: ${JSON.stringify(runtimeManifest)}`);
  }

  const bunRevision = run(runtimeBun, ["--revision"]);
  if (bunRevision !== runtimeManifest.bunRevision) {
    throw new Error(
      `Embedded Bun revision mismatch: expected ${runtimeManifest.bunRevision}, got ${bunRevision}`,
    );
  }

  process.stdout.write(`PACKAGED_LAUNCHER_INSPECT_OK win32/x64 ${expectedVersion}\n`);
}

main()
  .finally(() => fs.rmSync(scratch, { recursive: true, force: true }))
  .catch((error) => {
    process.stderr.write(`${error?.stack || error}\n`);
    process.exitCode = 1;
  });
