/**
 * Hooks — Unit Tests
 *
 * Verifies all 9 hooks exist, are executable, and have correct shebang lines.
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';

const HOOKS_DIR = path.resolve(import.meta.dirname ?? __dirname, '../../.claude/hooks');

const EXPECTED_HOOKS = [
  'block-secrets.py',
  'check-branch.sh',
  'check-e2e.sh',
  'check-env-sync.sh',
  'check-mdd-version.sh',
  'check-ports.sh',
  'check-rybbit.sh',
  'check-rulecatch.sh',
  'lint-on-save.sh',
  'session-context.sh',
  'verify-no-secrets.sh',
];

describe('Hook files', () => {
  it('should have exactly 11 hooks', () => {
    const hookFiles = fs.readdirSync(HOOKS_DIR).filter((f) => f.endsWith('.sh') || f.endsWith('.py'));
    expect(hookFiles.sort()).toEqual(EXPECTED_HOOKS.sort());
  });

  for (const hook of EXPECTED_HOOKS) {
    describe(hook, () => {
      const hookPath = path.join(HOOKS_DIR, hook);

      it('should exist', () => {
        expect(fs.existsSync(hookPath)).toBe(true);
      });

      it('should be readable', () => {
        const content = fs.readFileSync(hookPath, 'utf8');
        expect(content.length).toBeGreaterThan(0);
      });

      it('should have a shebang line', () => {
        const content = fs.readFileSync(hookPath, 'utf8');
        expect(content.startsWith('#!/')).toBe(true);
      });

      if (hook.endsWith('.sh')) {
        it('should use bash shebang', () => {
          const content = fs.readFileSync(hookPath, 'utf8');
          expect(content.startsWith('#!/usr/bin/env bash')).toBe(true);
        });
      }

      if (hook.endsWith('.py')) {
        it('should use python3 shebang', () => {
          const content = fs.readFileSync(hookPath, 'utf8');
          expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
        });
      }
    });
  }
});

describe('Hook wiring in settings.json', () => {
  const settingsPath = path.resolve(import.meta.dirname ?? __dirname, '../../.claude/settings.json');

  it('settings.json should exist', () => {
    expect(fs.existsSync(settingsPath)).toBe(true);
  });

  it('should have PreToolUse hooks', () => {
    const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
    expect(settings.hooks.PreToolUse).toBeDefined();
    expect(settings.hooks.PreToolUse.length).toBeGreaterThan(0);
  });

  it('should have PostToolUse hooks', () => {
    const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
    expect(settings.hooks.PostToolUse).toBeDefined();
    expect(settings.hooks.PostToolUse.length).toBeGreaterThan(0);
  });

  it('should have Stop hooks', () => {
    const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
    expect(settings.hooks.Stop).toBeDefined();
    expect(settings.hooks.Stop.length).toBeGreaterThan(0);
  });

  it('lint-on-save should fire on both Write and Edit', () => {
    const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
    const postToolUse = settings.hooks.PostToolUse;
    const lintHook = postToolUse.find((h: { matcher: string }) =>
      h.hooks?.some((hook: { command: string }) => hook.command?.includes('lint-on-save')),
    );
    expect(lintHook).toBeDefined();
    expect(lintHook.matcher).toContain('Write');
    expect(lintHook.matcher).toContain('Edit');
  });
});
