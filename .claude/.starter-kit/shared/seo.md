<!-- Part of /new-project scaffolding. Read via .claude/commands/new-project.md when the selection requires it; not a standalone command. -->

## Mandatory SEO (ALL Web Projects)

Every web project MUST include these SEO fundamentals. This is non-negotiable for any page that serves HTML.

### 1. HTML Meta Tags (in layout/head)

```html
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Page Title — Site Name</title>
  <meta name="description" content="Concise page description (150-160 chars)">
  <meta name="robots" content="index, follow">
  <link rel="canonical" href="https://example.com/current-page">

  <!-- Open Graph (Facebook, LinkedIn, Discord) -->
  <meta property="og:type" content="website">
  <meta property="og:title" content="Page Title">
  <meta property="og:description" content="Page description">
  <meta property="og:image" content="https://example.com/og-image.png">
  <meta property="og:url" content="https://example.com/current-page">
  <meta property="og:site_name" content="Site Name">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Page Title">
  <meta name="twitter:description" content="Page description">
  <meta name="twitter:image" content="https://example.com/og-image.png">
</head>
```

### 2. JSON-LD Structured Data (schema.org)

EVERY web project must include at minimum an Organization or WebSite schema:

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Your Site Name",
  "url": "https://example.com",
  "description": "Site description",
  "publisher": {
    "@type": "Organization",
    "name": "Your Organization",
    "logo": {
      "@type": "ImageObject",
      "url": "https://example.com/logo.png"
    }
  }
}
</script>
```

For specific page types, add the appropriate schema:
- **Article pages:** `@type: "Article"` with author, datePublished, dateModified
- **Product pages:** `@type: "Product"` with price, availability, reviews
- **FAQ pages:** `@type: "FAQPage"` with question/answer pairs
- **How-to pages:** `@type: "HowTo"` with steps
- **Breadcrumbs:** `@type: "BreadcrumbList"` on all pages with navigation depth

### 3. Technical SEO Files

Create these in the project root (or public directory):

**robots.txt:**
```
User-agent: *
Allow: /
Sitemap: https://example.com/sitemap.xml
```

**sitemap.xml** (or generate dynamically):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2025-01-01</lastmod>
    <priority>1.0</priority>
  </url>
</urlset>
```

### 4. Performance SEO

- Images MUST use WebP format with `alt` attributes
- Include `<link rel="preconnect">` for external domains (fonts, analytics, CDNs)
- Set proper cache headers for static assets
- Ensure Largest Contentful Paint (LCP) < 2.5 seconds

### 5. Framework-Specific SEO

**Next.js:**
- Use `metadata` export in layout.tsx / page.tsx (App Router)
- Use `generateMetadata()` for dynamic pages
- JSON-LD via `<script>` in layout or use `next-seo` package
- next/image for automatic WebP conversion and lazy loading
- Automatic sitemap generation with `next-sitemap`

**Vite + React (SPA):**
- Use `react-helmet-async` for dynamic `<head>` management
- For SEO-critical SPAs, consider prerendering with `vite-plugin-ssr` or `prerender-spa-plugin`
- NOTE: SPAs have inherent SEO limitations — if SEO is critical, recommend SSR

**Astro:**
- Built-in `<head>` management in `.astro` layouts
- Automatic sitemap with `@astrojs/sitemap`
- Built-in image optimization

