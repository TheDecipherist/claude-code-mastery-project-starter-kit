---
name: web-architecture
description: Choosing how a web app renders and whether to use a framework, decided up front. Claude defaults to client-side rendering and hand-rolled vanilla HTML/JS, which is usually the wrong starting point for content sites and multi-page apps. Use when starting or scaffolding a site or app, deciding how pages render (SSR, SSG, CSR), or about to hand-build routing and state. Covers defaulting to server-rendered HTML for first paint and SEO, reaching for a framework when there are several pages, and not over-engineering a single page.
when_to_use: |
  - Starting, scaffolding, or proposing the structure for a website or web app
  - Deciding how pages render: server-rendered (SSR), static (SSG), or client-rendered (CSR/SPA)
  - The project has several pages, shared layout, routing, or data fetching, raise a framework even if the user didn't ask
  - About to hand-roll routing, navigation, or rendering in vanilla JS for a multi-page app
  - Do NOT push a framework for a single trivial static page, or for backend/native work
---

# Web Architecture: Pick the Rendering Strategy Up Front

Two defaults Claude reaches for that are usually wrong: rendering everything in the browser, and hand-building a multi-page app from vanilla HTML/JS. Both should be a deliberate up-front choice, and for most real sites the better answer is server-rendered HTML and a framework. Raise these even when the user didn't ask, the same way you'd raise a WAF before production.

## Default to server-rendered HTML, not client-rendered

For anything where content, SEO, or first paint matters, the content must be in the initial HTML response, not painted afterward by client JavaScript. Client-side rendering (a blank shell that fetches and renders in the browser) means a blank screen until the bundle loads and runs, a slow LCP, and content that many crawlers and LLM retrievers never see because they don't reliably execute JavaScript. Server-render it instead:

- **SSG (static generation):** render at build time, serve static from a CDN. Fastest, cheapest, most cacheable. The default for content that doesn't change per request, marketing, docs, blog, listing and category pages that can be rebuilt.
- **SSR (server-side rendering):** render per request on the server. For dynamic, personalized, or auth-gated content that can't be baked at build time.
- **CSR / islands:** render in the browser only for the genuinely interactive parts, or for app-like surfaces behind a login where SEO is irrelevant (a dashboard). With an islands approach (Astro) the page ships as static HTML and only the interactive components hydrate.

Pick per page, you can mix: a static marketing page (SSG), a personalized account page (SSR), and an interactive widget (an island) in the same site.

## Several pages means reach for a framework

If the project has multiple pages, a shared layout, routing, or real data fetching, hand-rolling it in vanilla JS is a maintenance and performance trap, and it's Claude's default unless told otherwise. Reach for a framework (Next.js, Astro, SvelteKit, Nuxt, Remix). They give routing, SSR and SSG, code-splitting, data loading, and image optimization out of the box, and crucially they give you SPA-style client navigation on top of server-rendered initial HTML, so you get the smooth multi-page app feel without shipping a blank client-only SPA that breaks first paint and SEO.

Note the distinction: a pure client-rendered SPA is the thing to avoid for content sites. A framework that does SSR/SSG with client-side navigation gives you the app experience and keeps the content in the HTML.

## But match the tool to the project

Don't overcorrect. A single static page, a landing page, or a tiny embeddable widget does not need Next.js, plain HTML and CSS is the right, lighter call, and reaching for a heavy framework there is its own mistake. The failure runs both ways; the common one is under-reaching (vanilla everything, rendered in the browser), but over-engineering a trivial page is real too. The decision is: how many pages, does content need to be crawlable and fast, and how interactive is it, then pick the lightest thing that satisfies those.

---

This skill is built to grow. Add a rule when a real architecture call has a stable, defensible answer.
