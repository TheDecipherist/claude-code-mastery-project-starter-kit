---
name: responsive-css
description: Writing CSS and markup that works on phone and desktop at the same time, the responsive failures Claude repeats. Use when building or editing any web page or component, or when something overflows horizontally, a code block blows out the page, text is huge on mobile, or content won't scroll on touch. Covers the viewport meta tag, the flex/grid min-width:0 rule that fixes most overflow, code blocks that scroll instead of overflowing, fluid type with clamp(), and mobile-first breakpoints. This is authoring guidance, design-review evaluates the result.
when_to_use: |
  - Writing or editing CSS or HTML for a page or component that renders in a browser
  - Anything that has to look right on both a phone and a desktop
  - Fixing horizontal page overflow, a code block or table that overflows, text too large on mobile, or a region that won't scroll on touch
  - The whole page suddenly scrolls, jumps, or rubber-bands on iPhone/Safari, or background scrolls under an open modal
  - Building docs/landing pages with code blocks, which overflow on mobile constantly
  - Do NOT use for native mobile (React Native, Flutter) or non-visual code
---

# Responsive CSS: Mobile and Desktop at Once

Claude writes CSS for the desktop it's picturing and never checks the narrow viewport, so the same few things break every time: content overflows sideways, code blocks blow out the page, and text that's right on desktop is huge on a phone. Design for the small screen first and these mostly disappear.

## Set the viewport, stop iOS inflating text

Without the viewport meta tag, mobile browsers render at a ~980px layout width and scale the result down, which is why everything looks oversized and mis-laid-out on a phone. This one line is non-negotiable on every page:

```html
<meta name="viewport" content="width=device-width, initial-scale=1" />
```

And stop iOS from auto-enlarging text:

```css
html { -webkit-text-size-adjust: 100%; text-size-adjust: 100%; }
```

## The flex/grid `min-width: 0` rule, this fixes most overflow

This is the single most common cause of mysterious horizontal scroll. Flex and grid children default to `min-width: auto`, which means they refuse to shrink below their content's intrinsic width. So one long line, a URL, or a `<pre>` inside a flex/grid item pushes the whole layout wider than the screen. Set `min-width: 0` on the child (or `overflow: hidden`) and it shrinks correctly.

```css
.flex-child, .grid-child { min-width: 0; }   /* lets long content shrink instead of overflowing */
```

If you fix nothing else, fix this. It's behind the code-block overflow in most "works on desktop, scrolls sideways on mobile" pages.

## Code blocks scroll, they don't overflow the page

A `<pre>` doesn't wrap and has no scroll affordance by default, so long lines expand the page. Make the block scroll inside itself, and never line-wrap code (wrapping changes what the code means). The parent needs `min-width: 0` per the rule above, or this still overflows.

```css
pre {
  overflow-x: auto;     /* scroll inside the block */
  max-width: 100%;
}
pre code { white-space: pre; }   /* keep code on its own lines, scroll horizontally */
```

For prose, the opposite: let long words and URLs break instead of overflowing.

```css
p, li, h1, h2, h3 { overflow-wrap: break-word; }
```

Wrap wide tables the same way you handle code, in a scroll container: `<div style="overflow-x:auto">…table…</div>`.

## Fluid type with `clamp()`, not fixed desktop sizes

A heading sized for desktop is enormous on a phone and forces wrapping and overflow. `clamp()` scales the size smoothly between a mobile floor and a desktop ceiling with no breakpoints to juggle:

```css
h1   { font-size: clamp(1.75rem, 4vw + 1rem, 3rem); }
body { font-size: clamp(1rem, 0.5vw + 0.9rem, 1.125rem); line-height: 1.5; }
```

The middle value does the scaling; the floor and ceiling keep it readable at both ends.

## Mobile-first: base styles small, enhance up

Write the base styles for the narrow screen, then add `@media (min-width: ...)` to enhance for larger ones. Desktop-first with `max-width` patches is exactly how you get a layout that works on the desktop and falls apart on mobile, because the mobile case is an afterthought bolted on.

```css
.layout { display: grid; grid-template-columns: 1fr; gap: 1rem; }   /* phone */
@media (min-width: 48rem) {
  .layout { grid-template-columns: 240px 1fr; }                     /* tablet up */
}
```

Check the phone width first, not last.

## Sideways scroll: the rest of the causes, and the touch-scroll bug

If the page scrolls horizontally on mobile, the `min-width: 0` rule above is the first thing to check. The other usual suspects:

- **Set `box-sizing: border-box` globally.** Without it, `width: 100%` plus any `padding` or `border` adds up to wider than the parent and overflows. This is a top cause of sideways scroll and Claude often omits it from scratch CSS:
```css
*, *::before, *::after { box-sizing: border-box; }
```
- **No fixed pixel widths wider than the phone.** `width: 800px` or `min-width: 600px` on a 375px screen forces horizontal scroll. Use `max-width`, percentages, or `min(800px, 100%)` so the element caps at the viewport.
- **Watch positioned and decorative elements.** Absolutely positioned, transformed, or negative-margin elements (offset images, background blobs, things nudged with `right:` or `translateX`) stick out past the right edge and widen the scrollable area even when the layout looks fine. Constrain them, or clip on a wrapper with `overflow-x: clip` (preferred over `hidden`, it doesn't create a scroll container and so won't break `position: sticky`).
- **Use `width: 100%`, not `100vw`.** `100vw` includes the scrollbar width, so a full-width element ends up wider than the content area and scrolls the page sideways.
- **Cap media, and give images dimensions:** `img, video, svg, canvas { max-width: 100%; height: auto; }`, and set the intrinsic `width`/`height` attributes on every `<img>` so the browser reserves the box and the page doesn't shift or repaint when the image loads (see web-performance).
- **Don't paper over it with `body { overflow-x: hidden }`.** That hides the symptom and breaks `position: sticky`. Find the offender: temporarily add `* { outline: 1px solid red; }` (outline, not border, so it doesn't change layout) and look for the element wider than the viewport, then fix that element.
- **Can't scroll a code block or editor on touch?** It's almost always an ancestor with `overflow: hidden` clipping it, or the region has a fixed height with no `overflow: auto`. Give the scroll region `overflow: auto` and a sane `max-height`, and make sure no ancestor sets `overflow: hidden` or `touch-action: none` over it.

## iOS Safari: when the whole page suddenly scrolls or jumps

A classic, and it's almost always one of four iOS-specific behaviors, each with a different fix:

- **Scroll chaining.** Drag inside a scrollable region (a modal, drawer, code block, chat list), hit its top or bottom, keep dragging, and the scroll "leaks" to the page so the whole thing moves and rubber-bands underneath. Stop it by containing the scroll on that region:
```css
.modal-body, .drawer, .scroll-region { overscroll-behavior: contain; }
```
- **Background scrolls under an open modal.** `body { overflow: hidden }` does not reliably hold on iOS Safari, the page still scrolls behind the overlay. The robust lock is to fix the body and restore the scroll position on close:
```js
// open:  remember position, freeze the body in place
const y = window.scrollY;
document.body.style.cssText = `position:fixed; top:${-y}px; left:0; right:0;`;
// close: release and jump back exactly where they were
document.body.style.cssText = "";
window.scrollTo(0, y);
```
- **The `100vh` toolbar jump.** On iOS, `100vh` counts the area behind Safari's address bar, so a `height:100vh` section is taller than the visible viewport and the page jumps as the toolbar shows and hides. Use the dynamic viewport unit instead, with a legacy fallback:
```css
.full-height { height: 100vh; height: 100dvh; }   /* dvh tracks the real visible height */
```
- **Tap an input and the page zooms and scrolls.** iOS Safari auto-zooms when you focus an input whose `font-size` is under 16px, which scrolls and rescales the whole page. Give form controls at least 16px. Do not "fix" this with `maximum-scale=1` or `user-scalable=no`, that disables pinch-zoom and hurts accessibility.
```css
input, select, textarea { font-size: 16px; }
```

---

This skill is built to grow. Add a rule when a real responsive failure has a stable, defensible fix.
