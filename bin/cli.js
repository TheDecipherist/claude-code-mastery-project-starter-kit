#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import os from 'os';
import https from 'https';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PKG_ROOT = path.resolve(__dirname, '..');

// ── low-level helpers (declared first — no hoisting dependency) ───────────────

function paths(homeDir) {
  const claudeDir = path.join(homeDir, '.claude');
  return { claudeDir, starterKitDir: path.join(claudeDir, 'starter-kit') };
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function symlinkEntry(src, dest, label) {
  if (fs.existsSync(dest)) {
    if (fs.lstatSync(dest).isSymbolicLink()) return; // already linked
    console.log(`  ⚠  Skipped ${label} — existing user file at ${dest}`);
    return;
  }
  fs.symlinkSync(src, dest);
  console.log(`  Linked ${label}`);
}

function symlinkFiles(srcDir, destDir) {
  if (!fs.existsSync(srcDir)) return;
  ensureDir(destDir);
  for (const name of fs.readdirSync(srcDir)) {
    symlinkEntry(path.join(srcDir, name), path.join(destDir, name), name);
  }
}

function symlinkDirs(srcDir, destDir) {
  if (!fs.existsSync(srcDir)) return;
  ensureDir(destDir);
  for (const name of fs.readdirSync(srcDir)) {
    const src = path.join(srcDir, name);
    if (fs.statSync(src).isDirectory()) {
      symlinkEntry(src, path.join(destDir, name), name);
    }
  }
}

function readInstalledVersion(homeDir) {
  const { starterKitDir } = paths(homeDir);
  const versionFile = path.join(starterKitDir, 'version');
  return fs.existsSync(versionFile) ? fs.readFileSync(versionFile, 'utf8').trim() : null;
}

function fetchLatestVersion() {
  return new Promise((resolve, reject) => {
    https.get(
      'https://registry.npmjs.org/@claude-code-mastery/starter-kit/latest',
      { headers: { Accept: 'application/json' } },
      res => {
        let body = '';
        res.on('data', chunk => { body += chunk; });
        res.on('end', () => {
          try { resolve(JSON.parse(body).version); } catch { reject(new Error('parse')); }
        });
      },
    ).on('error', reject);
  });
}

// ── exported helpers ──────────────────────────────────────────────────────────

export function rewriteHookPath(command, starterKitDir) {
  return command.replace(/(?<=^|\s)\.claude\/hooks\//g, `${starterKitDir}/hooks/`);
}

export function copyPackageFiles(homeDir = os.homedir()) {
  const { starterKitDir } = paths(homeDir);
  ensureDir(starterKitDir);
  fs.cpSync(path.join(PKG_ROOT, '.claude'), starterKitDir, { recursive: true, force: true });
  const pkg = JSON.parse(fs.readFileSync(path.join(PKG_ROOT, 'package.json'), 'utf8'));
  fs.writeFileSync(path.join(starterKitDir, 'version'), pkg.version, 'utf8');
  console.log(`  Copied package files → ${starterKitDir}`);
}

export function symlinkAll(homeDir = os.homedir()) {
  const { claudeDir, starterKitDir } = paths(homeDir);
  symlinkFiles(path.join(starterKitDir, 'commands'), path.join(claudeDir, 'commands'));
  symlinkDirs(path.join(starterKitDir, 'skills'),   path.join(claudeDir, 'skills'));
  symlinkFiles(path.join(starterKitDir, 'agents'),  path.join(claudeDir, 'agents'));
}

export function mergeSettings(homeDir = os.homedir()) {
  const { claudeDir, starterKitDir } = paths(homeDir);
  const kitPath = path.join(starterKitDir, 'settings.json');
  if (!fs.existsSync(kitPath)) return;

  const kit    = JSON.parse(fs.readFileSync(kitPath, 'utf8'));
  const glPath = path.join(claudeDir, 'settings.json');
  const gl     = fs.existsSync(glPath) ? JSON.parse(fs.readFileSync(glPath, 'utf8')) : {};
  if (!gl.hooks) gl.hooks = {};

  for (const [event, groups] of Object.entries(kit.hooks ?? {})) {
    if (!gl.hooks[event]) gl.hooks[event] = [];

    for (const group of groups) {
      const rewritten = (group.hooks ?? []).map(h => ({
        ...h,
        command: rewriteHookPath(h.command ?? '', starterKitDir),
      }));

      const registered = new Set(
        gl.hooks[event].flatMap(g => (g.hooks ?? []).map(h => h.command)),
      );
      const fresh = rewritten.filter(h => !registered.has(h.command));
      if (fresh.length === 0) continue;

      const existing = gl.hooks[event].find(g => g.matcher === group.matcher);
      if (existing) {
        existing.hooks.push(...fresh);
      } else {
        gl.hooks[event].push({ ...group, hooks: fresh });
      }
      for (const h of fresh) console.log(`  Registered hook: ${h.command}`);
    }
  }

  fs.writeFileSync(glPath, JSON.stringify(gl, null, 2), 'utf8');
}

// ── main commands ─────────────────────────────────────────────────────────────

export async function init(homeDir = os.homedir()) {
  const { claudeDir, starterKitDir } = paths(homeDir);
  console.log('Installing @claude-code-mastery/starter-kit...\n');
  copyPackageFiles(homeDir);
  symlinkAll(homeDir);
  mergeSettings(homeDir);
  // Copy conf to ~/.claude/ and record source path
  const confSrc = path.join(PKG_ROOT, 'claude-mastery-project.conf');
  if (fs.existsSync(confSrc)) {
    ensureDir(claudeDir);
    fs.copyFileSync(confSrc, path.join(claudeDir, 'claude-mastery-project.conf'));
    console.log(`  Copied claude-mastery-project.conf → ${claudeDir}`);
  }
  fs.writeFileSync(path.join(claudeDir, 'starter-kit-source-path'), starterKitDir, 'utf8');
  const version = readInstalledVersion(homeDir);
  console.log(`\n✅ Installed v${version} to ${starterKitDir}`);
  console.log('   Run /starter-kit update inside Claude Code to update in future.\n');
}

export async function update(homeDir = os.homedir()) {
  const { starterKitDir } = paths(homeDir);
  if (!fs.existsSync(starterKitDir)) {
    console.error('Not installed. Run: npx @claude-code-mastery/starter-kit init');
    process.exit(1);
  }
  console.log(`Updating from v${readInstalledVersion(homeDir)}...\n`);
  copyPackageFiles(homeDir);
  symlinkAll(homeDir);
  mergeSettings(homeDir);
  console.log(`\n✅ Updated to v${readInstalledVersion(homeDir)}`);
}

export async function status(homeDir = os.homedir()) {
  const installed = readInstalledVersion(homeDir);
  if (!installed) {
    console.log('Not installed. Run: npx @claude-code-mastery/starter-kit init');
    return;
  }
  console.log(`Installed: v${installed}`);
  try {
    const latest = await fetchLatestVersion();
    console.log(latest === installed
      ? `Latest:    v${latest} (up to date ✅)`
      : `Latest:    v${latest} (run /starter-kit update to upgrade)`);
  } catch {
    console.log('Latest:    (could not reach npm registry)');
  }
}

// ── entry point ───────────────────────────────────────────────────────────────

const isMain = process.argv[1] && __filename === fs.realpathSync(process.argv[1]);
if (isMain) {
  const subcommand = process.argv[2];
  switch (subcommand) {
    case 'init':   await init();   break;
    case 'update': await update(); break;
    case 'status': await status(); break;
    default:
      console.log('Usage: npx @claude-code-mastery/starter-kit <init|update|status>');
      process.exit(1);
  }
}
