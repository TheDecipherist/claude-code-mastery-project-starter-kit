---
name: accessibility
description: Accessibility and screen-reader support, built in from the start rather than bolted on. Claude treats a11y as an afterthought and reaches for clickable divs, skips alt text and labels, and removes focus rings. Use when building or editing any UI, page, or interactive component. Covers semantic HTML before ARIA, real buttons and links, accessible names, keyboard operability and focus management, headings and landmarks, contrast and motion, and how to actually test it. Most of it is free if you use the right element.
when_to_use: |
  - Building or editing any UI, page, form, or interactive component, treat a11y as a default, not a later pass
  - Anything with buttons, links, forms, modals, menus, tabs, or icons
  - About to use a clickable `<div>`, skip `alt` or a label, remove a focus outline, or disable zoom
  - Dynamic content that updates without a full page load (toasts, async results, SPA route changes)
  - Do NOT skip this for "internal" tools, accessibility is not optional there either
---

# Accessibility: Build It In, Don't Bolt It On

Accessibility is a current best practice, not a nice-to-have for later, and most of it costs nothing if you use the right elements from the start. Claude's defaults (clickable divs, missing labels, removed focus rings) are exactly what breaks screen readers and keyboards, and they're expensive to retrofit. Treat it as part of the build, like you would performance.

## Semantic HTML first, ARIA last

The native element gives you keyboard support, focus, the correct role, and screen-reader semantics for free. The first rule of ARIA is don't use ARIA when a native element already does the job, and bad ARIA is worse than none. Reach for the real element before reaching for a role.

## Use the real element, not a clickable div

`<button>` for actions (submit, toggle, open a menu), `<a href>` for navigation (it goes somewhere). A `<div onclick>` is none of these: it isn't focusable, doesn't fire on Enter or Space, and is announced as nothing. Recreating a button with `role`, `tabindex`, and keydown handlers is work you will get subtly wrong, the native `<button>` is already all of that. Same for `<nav>`, `<ul>`, `<table>`, `<label>`, `<input>`, use them.

## Every interactive thing needs an accessible name

- **Images:** a descriptive `alt`, or `alt=""` for purely decorative ones so screen readers skip them. Never omit the attribute, that makes the reader announce the filename.
- **Form fields:** a real `<label>` tied to the input (`for`/`id` or wrapping). A `placeholder` is not a label, it vanishes on input, has poor contrast, and isn't reliably announced.
- **Icon-only buttons** (hamburger, close X, search): an `aria-label`. This is the single most common missing name, an icon button with no text is silent to a screen reader.

## Keyboard and focus

Everything interactive must be reachable and operable by keyboard in a sensible order. Two things Claude breaks constantly:

- **Never remove the focus ring** (`outline: none`) without replacing it, a keyboard user then can't see where they are. Use `:focus-visible` to show a clear ring for keyboard users without it appearing on mouse clicks.
- **Manage focus on modals and route changes.** Prefer the native `<dialog>` with `showModal()`, it traps focus, closes on Escape, and restores focus to the trigger. If you build your own, replicate all of that. In a SPA, move focus to the new view's heading on navigation, or a screen-reader user never learns the page changed.

## Structure: headings, landmarks, and sectioning

Headings are the outline that screen readers and search engines navigate by, so get them right:

- **One `<h1>` per page**, the page's title. Then `<h2>`/`<h3>` in order, don't skip levels for visual size (style with CSS, keep the order logical).
- **Use real heading elements, not a styled `<span>` or `<div>`.** Something that just looks like a heading carries no meaning, assistive tech and crawlers don't see a heading at all. And don't wrap the heading text in a `<span>` to style it, style the heading element (or a class on it) directly, the heading's content should be the heading text.
- **Keep a heading next to the content it labels.** A heading describes the block that immediately follows it, so the heading and its paragraph belong together, heading first, grouped. A heading stranded away from its content, or with unrelated markup wedged between, loses the relationship that gives it meaning to both a reader and a crawler.

Then use the document-sectioning elements for what they mean, not as styled `<div>`s, so assistive tech can understand and navigate the page:

- **Landmarks** wrap the page's regions: `<header>` (banner), `<nav>`, `<main>` (one per page), `<aside>` (complementary), `<footer>` (contentinfo). Add a skip-to-content link to `<main>` so keyboard and screen-reader users can jump straight in instead of tabbing through the nav every time.
- **`<article>`** for a self-contained piece that stands on its own or repeats, a post, comment, card, product. It tells assistive tech "this is one discrete item," which is what makes a feed or list navigable.
- **`<section>`** for a thematic group, but only when it has a heading. A bare `<section>` is not a landmark and adds nothing, it becomes a navigable region only when you give it an accessible name (`aria-labelledby` pointing at its heading). If it's just a styling wrapper with no heading, use a `<div>`.

The rule both ways: reach for the element that describes the content, but overusing `<section>` and `<article>` as generic wrappers is as unhelpful as never using them.

## Don't lock people out: contrast, color, zoom, motion

- Text contrast at least 4.5:1 (3:1 for large text), and never convey meaning by color alone, pair it with text, an icon, or a pattern.
- Never disable zoom (`user-scalable=no` / `maximum-scale=1`), see responsive-css.
- Respect `prefers-reduced-motion` for animations and parallax.
- Announce dynamic changes (toasts, async results, validation) with an `aria-live` region, or they happen silently for a screen reader.

## Test it, don't assume it

Do a keyboard-only pass (Tab through everything, operate it with Enter/Space/Escape, watch the focus ring) and run an actual screen reader on the key flows. Automated tools (axe, Lighthouse) are worth running but catch only a fraction of issues, the keyboard and screen-reader pass is what finds the rest.

---

This skill is built to grow. Add a rule when a real accessibility failure has a stable, defensible fix.
