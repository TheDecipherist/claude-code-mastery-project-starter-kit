import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'fs';
import path from 'path';
import os from 'os';
import * as cli from '../../bin/cli.js';

describe('@claude-code-mastery/starter-kit CLI', () => {
  let tempHome: string;

  beforeEach(() => {
    tempHome = fs.mkdtempSync(path.join(os.tmpdir(), 'starter-kit-test-'));
  });

  afterEach(() => {
    fs.rmSync(tempHome, { recursive: true, force: true });
  });

  describe('init', () => {
    it('should create ~/.claude/starter-kit/ with package files', async () => {
      await cli.init(tempHome);
      const starterKitDir = path.join(tempHome, '.claude', 'starter-kit');
      expect(fs.existsSync(starterKitDir)).toBe(true);
      expect(fs.existsSync(path.join(starterKitDir, 'commands'))).toBe(true);
      expect(fs.existsSync(path.join(starterKitDir, 'hooks'))).toBe(true);
    });

    it('should symlink each command into ~/.claude/commands/', async () => {
      await cli.init(tempHome);
      const commandsDir = path.join(tempHome, '.claude', 'commands');
      expect(fs.existsSync(commandsDir)).toBe(true);
      const entries = fs.readdirSync(commandsDir);
      expect(entries.length).toBeGreaterThan(0);
      const first = path.join(commandsDir, entries[0]);
      expect(fs.lstatSync(first).isSymbolicLink()).toBe(true);
    });

    it('should symlink each skill into ~/.claude/skills/', async () => {
      await cli.init(tempHome);
      const skillsDir = path.join(tempHome, '.claude', 'skills');
      expect(fs.existsSync(skillsDir)).toBe(true);
      const entries = fs.readdirSync(skillsDir);
      expect(entries.length).toBeGreaterThan(0);
      const first = path.join(skillsDir, entries[0]);
      expect(fs.lstatSync(first).isSymbolicLink()).toBe(true);
    });

    it('should symlink each agent into ~/.claude/agents/', async () => {
      await cli.init(tempHome);
      const agentsDir = path.join(tempHome, '.claude', 'agents');
      expect(fs.existsSync(agentsDir)).toBe(true);
      const entries = fs.readdirSync(agentsDir);
      expect(entries.length).toBeGreaterThan(0);
    });

    it('should register hooks with absolute paths in ~/.claude/settings.json', async () => {
      await cli.init(tempHome);
      const settingsPath = path.join(tempHome, '.claude', 'settings.json');
      expect(fs.existsSync(settingsPath)).toBe(true);
      const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
      const allCommands: string[] = Object.values(settings.hooks ?? {})
        .flat()
        .flatMap((g: any) => g.hooks ?? [])
        .map((h: any) => h.command ?? '');
      const hasRelativePath = allCommands.some(c => c.includes('.claude/hooks/'));
      expect(hasRelativePath).toBe(false);
      const hasAbsolutePath = allCommands.some(c => c.includes('starter-kit/hooks/'));
      expect(hasAbsolutePath).toBe(true);
    });

    it('should write ~/.claude/starter-kit-source-path pointing to starter-kit dir', async () => {
      await cli.init(tempHome);
      const sourcePath = path.join(tempHome, '.claude', 'starter-kit-source-path');
      expect(fs.existsSync(sourcePath)).toBe(true);
      const content = fs.readFileSync(sourcePath, 'utf8').trim();
      expect(content).toContain('starter-kit');
    });

    it('should not overwrite an existing user command (non-symlink) without prompting', async () => {
      const commandsDir = path.join(tempHome, '.claude', 'commands');
      fs.mkdirSync(commandsDir, { recursive: true });
      const userFile = path.join(commandsDir, 'review.md');
      fs.writeFileSync(userFile, '# my custom review', 'utf8');

      await cli.init(tempHome);

      // User's file should still be a regular file, not a symlink
      expect(fs.lstatSync(userFile).isSymbolicLink()).toBe(false);
      expect(fs.readFileSync(userFile, 'utf8')).toBe('# my custom review');
    });

    it('should create ~/.claude/commands/ if it does not exist', async () => {
      await cli.init(tempHome);
      expect(fs.existsSync(path.join(tempHome, '.claude', 'commands'))).toBe(true);
    });
  });

  describe('update', () => {
    it('should overwrite files in ~/.claude/starter-kit/ with latest package content', async () => {
      await cli.init(tempHome);
      // Corrupt a file in starter-kit/
      const testFile = path.join(tempHome, '.claude', 'starter-kit', 'version');
      fs.writeFileSync(testFile, '0.0.0', 'utf8');
      await cli.update(tempHome);
      // Should be restored to actual version
      const version = fs.readFileSync(testFile, 'utf8').trim();
      expect(version).not.toBe('0.0.0');
    });

    it('should add symlinks for new commands added since last install', async () => {
      await cli.init(tempHome);
      // Simulate a new command appearing in starter-kit after update
      const starterKitCommands = path.join(tempHome, '.claude', 'starter-kit', 'commands');
      fs.writeFileSync(path.join(starterKitCommands, 'new-command.md'), '# new', 'utf8');
      await cli.update(tempHome);
      const link = path.join(tempHome, '.claude', 'commands', 'new-command.md');
      expect(fs.existsSync(link)).toBe(true);
    });

    it('should not touch user-created files (regular files) in ~/.claude/commands/', async () => {
      await cli.init(tempHome);
      const userFile = path.join(tempHome, '.claude', 'commands', 'my-custom.md');
      fs.writeFileSync(userFile, '# user command', 'utf8');
      await cli.update(tempHome);
      expect(fs.existsSync(userFile)).toBe(true);
      expect(fs.lstatSync(userFile).isSymbolicLink()).toBe(false);
    });

    it('should register any new hooks added since last install', async () => {
      await cli.init(tempHome);
      const countBefore = hookCount(tempHome);

      // Simulate a new hook arriving in starter-kit/settings.json after update
      // (update() calls copyPackageFiles first, so we patch after and call mergeSettings directly)
      const kitSettingsPath = path.join(tempHome, '.claude', 'starter-kit', 'settings.json');
      const kitSettings = JSON.parse(fs.readFileSync(kitSettingsPath, 'utf8'));
      if (!kitSettings.hooks.Stop) kitSettings.hooks.Stop = [];
      kitSettings.hooks.Stop.push({ hooks: [{ type: 'command', command: 'bash .claude/hooks/new-hook.sh' }] });
      fs.writeFileSync(kitSettingsPath, JSON.stringify(kitSettings));

      cli.mergeSettings(tempHome);

      expect(hookCount(tempHome)).toBeGreaterThan(countBefore);
    });
  });

  describe('status', () => {
    it('should print the installed version from ~/.claude/starter-kit/version', async () => {
      await cli.init(tempHome);
      const output: string[] = [];
      const originalLog = console.log;
      console.log = (...args: unknown[]) => output.push(args.join(' '));
      await cli.status(tempHome);
      console.log = originalLog;
      expect(output.some(l => l.includes('Installed'))).toBe(true);
    });

    it('should indicate when no version is installed', async () => {
      const output: string[] = [];
      const originalLog = console.log;
      console.log = (...args: unknown[]) => output.push(args.join(' '));
      await cli.status(tempHome);
      console.log = originalLog;
      expect(output.some(l => l.includes('Not installed'))).toBe(true);
    });
  });

  describe('settings.json merge', () => {
    it('should create settings.json if it does not exist', async () => {
      await cli.init(tempHome);
      expect(fs.existsSync(path.join(tempHome, '.claude', 'settings.json'))).toBe(true);
    });

    it('should merge hook entries without duplicating existing entries', async () => {
      await cli.init(tempHome);
      const countAfterFirst = hookCount(tempHome);
      await cli.mergeSettings(tempHome);
      const countAfterSecond = hookCount(tempHome);
      expect(countAfterSecond).toBe(countAfterFirst);
    });

    it('should preserve existing hooks from other tools when merging', async () => {
      const settingsPath = path.join(tempHome, '.claude', 'settings.json');
      fs.mkdirSync(path.join(tempHome, '.claude'), { recursive: true });
      fs.writeFileSync(settingsPath, JSON.stringify({
        hooks: {
          Stop: [{ hooks: [{ type: 'command', command: '/usr/local/bin/other-tool' }] }],
        },
      }));
      await cli.init(tempHome);
      const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
      const stopCommands = (settings.hooks?.Stop ?? [])
        .flatMap((g: any) => g.hooks ?? [])
        .map((h: any) => h.command);
      expect(stopCommands).toContain('/usr/local/bin/other-tool');
    });
  });
});

function hookCount(home: string): number {
  const settingsPath = path.join(home, '.claude', 'settings.json');
  if (!fs.existsSync(settingsPath)) return 0;
  const s = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
  return Object.values(s.hooks ?? {})
    .flat()
    .flatMap((g: any) => g.hooks ?? []).length;
}
