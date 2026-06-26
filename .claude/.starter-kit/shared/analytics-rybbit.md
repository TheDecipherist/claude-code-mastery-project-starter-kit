<!-- Part of /new-project scaffolding. Read via .claude/commands/new-project.md when the selection requires it; not a standalone command. -->

## Analytics: Rybbit (if selected)

When `rybbit` is selected as the analytics provider, scaffold tracking into the project:

### Required Environment Variables

```bash
# .env.example additions
NEXT_PUBLIC_RYBBIT_SITE_ID=your_rybbit_site_id
NEXT_PUBLIC_RYBBIT_URL=https://app.rybbit.io
```

### Next.js Integration (layout.tsx)

```tsx
<head>
  {process.env.NEXT_PUBLIC_RYBBIT_SITE_ID && (
    <script
      src={`${process.env.NEXT_PUBLIC_RYBBIT_URL || 'https://app.rybbit.io'}/api/script.js`}
      data-site-id={process.env.NEXT_PUBLIC_RYBBIT_SITE_ID}
      defer
    />
  )}
</head>
```

### Vite / Astro / Static HTML Integration

```html
<script
  src="https://app.rybbit.io/api/script.js"
  data-site-id="YOUR_SITE_ID"
  defer
></script>
```

### Docker Build Args (for Next.js on Dokploy)

When using both Rybbit + Dokploy + Next.js, the Rybbit env vars must be passed as build args:

```dockerfile
ARG NEXT_PUBLIC_RYBBIT_SITE_ID
ARG NEXT_PUBLIC_RYBBIT_URL
ENV NEXT_PUBLIC_RYBBIT_SITE_ID=$NEXT_PUBLIC_RYBBIT_SITE_ID
ENV NEXT_PUBLIC_RYBBIT_URL=$NEXT_PUBLIC_RYBBIT_URL
```

### Important
- Each website MUST have its own unique Rybbit site ID
- Create a new site in the Rybbit dashboard at https://app.rybbit.io
- NEVER reuse site IDs across different projects
- After deployment, verify the script is present in the page source

