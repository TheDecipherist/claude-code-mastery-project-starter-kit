---
name: web-performance
description: Web performance as an up-front design decision, not a later optimization pass. Use when building any user-facing page or component, deciding what loads when, or fixing a slow load or Core Web Vitals (LCP, CLS, INP). The organizing principle is to split what the user needs for first paint from what can wait, and build to that split from the start. Covers render-blocking CSS/JS, preloading the LCP element, lazy-loading the rest, reserving space to stop layout shift, and image/font/JS cost.
when_to_use: |
  - Building or structuring any user-facing page or component, decide the load strategy up front, not after
  - Deciding what to inline, preload, defer, or lazy-load
  - A page is slow to render, or Core Web Vitals (LCP, CLS, INP) need work
  - Adding images, fonts, scripts, or third-party tags to a page
  - Do NOT use for backend throughput tuning (that's elsewhere) or native apps
---

# Web Performance: Decide It Up Front

Performance is an architecture decision made at the start, not a cleanup pass at the end. The first question for anything user-facing is: what does the user need to see and interact with first, and what can wait. Build to that split. Loading everything eagerly and optimizing later is the expensive path, and it's the one Claude defaults to.

## Split first paint from later, and load each accordingly

Sort every resource into two buckets and treat them differently:

- **Critical, needed for first paint** (above the fold, the main content and its styles): put it in the initial HTML, inline the critical CSS (see css-structure), preload the largest image and the one critical font.
- **Later** (below the fold, interactions, secondary features, third-party): defer it. Lazy-load below-fold images and iframes natively with `loading="lazy"`, no JavaScript library or IntersectionObserver needed, the browser handles it, and on an iframe it defers heavy third-party embeds like maps and video players too. Then `defer` or `async` non-critical scripts, dynamic-import offscreen components and routes, and load analytics and third-party tags late and async.

## Don't let CSS or JS block first paint

CSS is render-blocking: a single large stylesheet delays the first paint until it's downloaded and parsed. Inline the above-the-fold slice and load the rest without blocking (`<link rel="preload" as="style" onload="this.rel='stylesheet'">`, or a `media` swap). A `<script>` in `<head>` without `defer` blocks HTML parsing; use `defer` (runs after parse, in order) or `async` (independent scripts), or put scripts at the end of `<body>`. Keep the number of render-blocking requests small.

## The LCP element gets priority and is never lazy-loaded

The Largest Contentful Paint is usually the hero image or headline above the fold, and it's the metric users feel as "has it loaded yet." Preload it, mark it `fetchpriority="high"`, and serve it correctly sized and compressed. Do NOT put `loading="lazy"` on it, that's a common mistake that delays the very thing LCP measures. Lazy-loading is for everything below the fold, not the first thing on screen.

## Reserve space so nothing shifts (CLS)

Layout shift is almost always a box whose size wasn't reserved before its contents arrived: the element loads late, shoves everything below it down, and the browser reflows and repaints.

**Always give images a `width` and `height` whenever you can.** Set the intrinsic pixel dimensions as HTML attributes so the browser reserves the correct box, and works out the aspect ratio, before a single image byte arrives. Pair it with CSS so it still scales responsively:

```html
<img src="hero.avif" width="1600" height="900" alt="..." />
```
```css
img { max-width: 100%; height: auto; }   /* scales to the column, keeps the reserved ratio */
```

Without the attributes the image takes up no height until it loads, then snaps to full size and pushes the page down. For backgrounds or anything where you can't set attributes, reserve the box with `aspect-ratio`. Do the same for video, ads, and embeds, and don't inject content above content that's already visible. For web fonts, use a `font-display` strategy with a size-adjusted fallback so text doesn't reflow when the real font swaps in. CLS is mostly "you didn't reserve the space."

## Images and fonts are usually the biggest wins

These two categories dwarf most JavaScript micro-tuning:

- **Images, convert to WebP (or AVIF).** WebP is typically 25 to 35% smaller than JPEG and much smaller than PNG at the same quality, and it supports transparency, so it replaces both. AVIF is smaller still where you can use it. This is often the single biggest size win on a page. Serve them through `<picture>` so the browser takes the best format it supports and older ones still get a fallback, and convert at build time (sharp in Node, or squoosh / cwebp):
```html
<picture>
  <source srcset="hero.avif" type="image/avif" />
  <source srcset="hero.webp" type="image/webp" />
  <img src="hero.jpg" width="1600" height="900" alt="..." />
</picture>
```
  Serve multiple resolutions natively too: a `srcset` of width variants plus `sizes` lets the browser download only the size that fits the viewport and pixel density, with no JavaScript. A phone grabs the small file, a retina desktop the large one, off one tag:
```html
<img src="img-800.webp" width="1600" height="900" alt="..."
     srcset="img-400.webp 400w, img-800.webp 800w, img-1600.webp 1600w"
     sizes="(max-width: 600px) 100vw, 800px" />
```
  The same `srcset`/`sizes` sit on each `<picture>` source to combine format and size, and `<picture>` with `media` also does art direction (a different crop per breakpoint). Two things not to convert: vector art (logos, icons) stays SVG, don't rasterize it, and animated GIFs should become video (MP4/WebM), a GIF is enormous. And actually compress, a full-resolution PNG hero is the most common single performance bug.
- **Fonts:** self-host or `preconnect`, subset to the characters used, preload the one critical face, and don't pull four weights when you use two.

## Ship less JavaScript

JS is the most expensive byte: it downloads, parses, and runs on the main thread, and a busy main thread is what makes taps and clicks feel slow (Interaction to Next Paint). Prefer built-ins and small dependencies (see nodejs), code-split so a route only loads its own code, tree-shake, and never block first paint or interaction on analytics or third-party tags. Less JavaScript beats faster JavaScript.

## Warm connections and the next navigation

Two cheap wins Claude almost never adds.

**Resource hints** prime the network before the browser would otherwise act:
- `dns-prefetch` resolves DNS early for a cross-origin host you'll use (analytics, a CDN, an image host). Nearly free, fine to list a few.
- `preconnect` does DNS + TCP + TLS for the handful of origins on the critical path (your font or image CDN). It's heavier, so reserve it for two or three and don't preconnect to origins this page won't use.
- `preload` fetches a current-page critical resource (the LCP image, the critical font) at high priority, and needs `as`. Don't preload everything, if it's all high priority, nothing is.
- `prefetch` fetches a resource for a likely next navigation at low priority and parks it in cache.

```html
<link rel="preconnect" href="https://cdn.example.com" crossorigin />
<link rel="dns-prefetch" href="https://analytics.example.com" />
<link rel="preload" as="image" href="/hero.avif" fetchpriority="high" />
```

**Speculate the next page on hover.** On a site where listing or category pages feed into detail pages, prefetch or prerender the destination the moment a user shows intent (hovers or starts to tap), so the navigation is instant. The native way is the Speculation Rules API, no JavaScript and no library:

```html
<script type="speculationrules">
{ "prerender": [{ "where": { "href_matches": "/product/*" }, "eagerness": "moderate" }] }
</script>
```

`eagerness: moderate` triggers on hover or pointerdown. `prerender` renders the whole page in the background so the click is instant; `prefetch` is the cheaper fetch-only version. Use `prerender` for high-confidence links, since it actually runs the destination's JavaScript, guard one-time side effects like analytics behind the prerender state so they don't fire until the user actually lands. It's Chromium-first today, so treat it as progressive enhancement, quicklink or instant.page is the fallback for other browsers.

## Measure with the real metrics, against a budget set at the start

Target Core Web Vitals, LCP, CLS, and INP, and set a performance budget when you start, not after it's slow. Lighthouse gives you the lab number; field data (CrUX or real-user monitoring) gives you the truth. The point of measuring is to hold the up-front decisions honest, not to discover at the end that the page is heavy.

---

This skill is built to grow. Add a rule when a real performance problem has a stable, defensible fix.
