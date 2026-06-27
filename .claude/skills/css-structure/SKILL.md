---
name: css-structure
description: Where CSS should live. Claude defaults to dumping a giant <style> block or scattering style="..." attributes instead of putting styles in a .css file and linking it. Use when building or editing a web page or component, or whenever about to write a style attribute or an embedded style block. Covers defaulting to an external stylesheet, why inline style attributes are a trap, and the few cases where inline is actually correct (dynamic values via custom properties, critical CSS, single-file artifacts, email).
when_to_use: |
  - Building or editing a web page or component and deciding where the styles go
  - About to write a `style="..."` attribute, a large embedded `<style>` block, or a per-element inline style object in JSX
  - Reviewing or refactoring how a project's CSS is organized
  - Do NOT use for native mobile styling or non-web code
---

# CSS Structure: Where Styles Live

Claude's default is to pour everything into one HTML file, either a big `<style>` block or `style="..."` attributes on each element. In a real project that's the wrong default. Styles belong in a `.css` file.

## Default: an external stylesheet, linked

When building a page or component in a project that has a file structure, put the CSS in its own file and link it:

```html
<link rel="stylesheet" href="/styles/app.css" />
```

It's reusable across pages, cached separately by the browser, keeps the markup readable, and lets the cascade and media queries work. This is the default to reach for instead of an inline block, not the thing to do only when asked.

## Avoid scattered inline `style="..."` attributes

Inline style attributes are the worst of the three options, for concrete reasons, not style preference:

- **They can't be responsive or interactive.** No media queries, no `:hover`/`:focus`, no `::before`/`::after`, no keyframes. An inline-styled element literally cannot be made responsive (see responsive-css), so it fights everything that skill is about.
- **They have the highest specificity short of `!important`.** Overriding an inline style later means escalating to `!important`, which starts a specificity war.
- **No reuse, no caching, noisy markup.** The same declarations get repeated on every element, ship on every page load, and bury the HTML structure.

## A single `<style>` block is fine for a deliberately single-file deliverable

Don't over-correct into "never embed." One `<style>` block in the head is the right call for a genuinely single-file thing: a standalone demo, a self-contained artifact, a quick reproduction. Email HTML is the opposite special case, mail clients strip `<style>` and external sheets, so email actually requires inline attributes. The rule is about defaults: the moment there's a project with folders, move the CSS into a file rather than defaulting to one big file because it's easier to paste.

## When inline is actually correct: dynamic and critical

Two cases where a value belongs inline:

- **Runtime values.** A width, transform, or color computed from state (a progress bar, a drag position) can't live in a static sheet. Set a CSS custom property inline and consume it in the stylesheet, so only the value is inline and the styling stays in CSS:
```html
<div class="bar" style="--progress: 73%"></div>
```
```css
.bar::after { width: var(--progress); }
```
- **Critical CSS.** Deliberately inlining the above-the-fold styles in `<head>` for first paint, then loading the rest, is a real performance technique, not the same mistake as scattering `style=`. Which styles are critical and what to defer is a first-paint decision, see web-performance.

## In React/JSX

Same split: dynamic values through `style={{}}` or a CSS variable, everything static in CSS Modules, a stylesheet, or utility classes (Tailwind). A large inline style object hand-written on every element is the JSX version of the same anti-pattern.

---

This skill is built to grow. Add a rule when a real styling-location decision has a stable, defensible answer.
