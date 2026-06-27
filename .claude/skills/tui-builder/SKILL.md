---
name: tui-builder
description: Use when building or modifying an interactive terminal UI (TUI), especially with Ink + React on Node, or when hitting terminal-resize rendering bugs — ghost/repeated content, a blank screen after resize, or a divider/layout that won't update width. Carries battle-tested resize rules Claude otherwise gets wrong. Not for plain non-interactive CLIs (flag parsing, scripts) with no full-screen rendering.
when_to_use: |
  - Building or modifying an interactive terminal UI (TUI), especially Ink + React on Node
  - Adding or fixing terminal-resize handling in a TUI
  - Debugging resize artifacts: ghosted/repeated content, blank screen after resize, stale divider/width
  - Do NOT use for plain non-interactive CLIs (argument parsing, batch scripts) with no live rendering
---

# Building Terminal UIs (TUIs)

Battle-tested rules from shipping Ink + React TUIs. The deep stack documented here is Ink/React on Node; the underlying principles — render into the alternate screen, control resize-handler ordering, treat size as state — transfer to other TUI frameworks even when the exact escape codes differ.

The thing to get right, because it's gotten wrong every time, is terminal **resize**. Ink renders by diffing its previous output and repositioning the cursor, not by clearing and redrawing. On resize that model breaks three ways at once:

- content Ink no longer "owns" stays visible
- the cursor lands at an unknown position, so Ink's positioning math is off
- a taller terminal re-reveals old lines that were previously offscreen

Every resize bug below is a variation of this one root cause.

## Rule 1 — Render into the alternate screen buffer

**Prevents:** ghost content — old frames stacking up, the logo repeating, a scrollbar appearing on resize.

**Why:** Ink writes to the normal terminal buffer, which has scrollback. Shrink the window and the terminal shows scrollback; grow it and old output is still in the buffer at the now-visible positions. Ink overwrites from the cursor but can't erase content it no longer knows about. The alternate screen has no scrollback at all, so there's nothing to bleed in from.

Enter with `\x1B[?1049h` before `render()`, exit with `\x1B[?1049l`. Hide the cursor (`\x1B[?25l`) while you're in it — cleaner, and it avoids cursor flicker on re-renders.

```typescript
// Before render():
process.stdout.write('\x1B[?1049h\x1B[?25l'); // enter alt screen, hide cursor
const restoreTerminal = () => process.stdout.write('\x1B[?25h\x1B[?1049l');
process.once('exit', restoreTerminal);
```

Always register the `process.once('exit', restoreTerminal)` handler so the terminal is restored even on crash. Skip it and you strand the user in alt-screen mode after the program exits.

## Rule 2 — Register the clear handler in the entry point, BEFORE `render()`

**Prevents:** the blank screen after resize — everything disappears except the active-tab highlight until the user presses a key.

**Why:** Node fires resize listeners in registration order. If you put the clear in a `useEffect`, it registers *after* `render()` (effects run post-mount, and `render()` is where Ink registers its own handler). So on resize, Ink's handler fires first and draws the full TUI, then your clear fires second and wipes everything Ink just drew. Ink thinks the frame is already drawn, so it doesn't redraw until the next state change.

Register the clear in the entry point before `render()`, so it ends up first in the queue and Ink draws onto an already-clean screen.

```typescript
// index.ts — register BEFORE render()
const clearOnResize = () => process.stdout.write('\x1B[2J\x1B[H');
process.stdout.on('resize', clearOnResize);

// Now call render() — Ink registers its handler here, AFTER ours
const { waitUntilExit } = render(...);

// Clean up on exit
process.stdout.off('resize', clearOnResize);
```

## Rule 3 — Track terminal width as React state

**Prevents:** the stale divider — width-dependent content (dividers, layout math) keeps its old width after resize until the user presses a key.

**Why:** Values computed from `process.stdout.columns` are read once at render time. After resize the columns value updates, but nothing triggers a React re-render. Make width state so the change propagates.

The resize handler in the root component does exactly one thing: update state. No escape codes, no clearing in here (the clear lives in the entry point, Rule 2).

```typescript
// App.tsx
const [termWidth, setTermWidth] = useState(process.stdout.columns ?? 80);

useEffect(() => {
  const onResize = () => setTermWidth(process.stdout.columns ?? 80);
  process.stdout.on('resize', onResize);
  return () => { process.stdout.off('resize', onResize); };
}, []);

// Use termWidth for anything that depends on terminal width
const divider = '─'.repeat(termWidth);
```

This handler registers after Ink's (correct), fires third, and triggers a second render. Ink diffs and updates only the changed line.

## Correct resize event order

Order is the whole game. When it's right:

1. `clearOnResize` (entry point, registered first) — clears the screen, cursor to (0,0).
2. Ink's internal handler (second) — recalculates layout with new dimensions, draws the full TUI onto the clean screen.
3. `setTermWidth` (root component, third) — the state update triggers a second render; Ink diffs and updates only the width-dependent lines.

## Never

- **Never use `\x1Bc` (RIS, reset to initial state).** It resets the entire terminal — colors, font, cursor settings — and behaves differently across emulators. Use `\x1B[2J\x1B[H` (clear + cursor home).
- **Never put the clear in a `useEffect`.** Effects run after mount, after Ink registers its handlers, so your clear will always fire after Ink draws.
- **Never write escape codes inside a component's render path** (outside effects). They fire during React's render phase and fight Ink's output buffer.
- **Never split resize logic across multiple conflicting handlers.** The clear lives in the entry point; state updates live in the root component. One job each, or the ordering becomes fragile.

## New-TUI checklist

- [ ] Alternate screen buffer (`\x1B[?1049h` / `\x1B[?1049l`) entered from the entry point
- [ ] Clear handler (`\x1B[2J\x1B[H`) registered in the entry point BEFORE `render()`
- [ ] Terminal width tracked as state in the root component
- [ ] Resize handler updates state only — no escape codes
- [ ] `process.once('exit', ...)` restores the terminal on exit and on crash
- [ ] Resize handlers cleaned up (`process.stdout.off(...)`) when the TUI exits
