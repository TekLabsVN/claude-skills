# Frontend Setup Reference — TanStack Start + Tailwind + shadcn/ui

## TanStack Start Overview

TanStack Start is a full-stack React framework built on TanStack Router with:
- File-based routing (similar to Next.js `app/` or Remix)
- SSR + SPA support
- Vite-powered build
- Type-safe navigation

---

## Scaffolding TanStack Start

From inside `apps/frontend/` (after clearing the AdonisJS placeholder):

```bash
# Option A: Using create-tsrouter-app (recommended)
npx create-tsrouter-app@latest . \
  --template file-router \
  --framework react \
  --bundler vite \
  --add-ons tailwind

# Option B: Manual (if you need more control)
npm create vite@latest . -- --template react-ts
npm install @tanstack/react-router @tanstack/start
```

> Always scaffold INSIDE `apps/frontend/`, not at the monorepo root.

---

## Resulting File Structure

```
apps/frontend/
├── src/
│   ├── routes/
│   │   ├── __root.tsx          ← Root layout
│   │   ├── index.tsx           ← / route
│   │   └── _authenticated/     ← Protected route group
│   ├── components/
│   │   └── ui/                 ← shadcn components go here
│   ├── lib/
│   │   └── client.ts           ← Tuyau + QueryClient
│   └── styles/
│       └── app.css             ← @import "tailwindcss"
├── app.config.ts               ← TanStack Start config
├── vite.config.ts
├── tsconfig.json
└── package.json
```

---

## app.config.ts (TanStack Start)

```ts
import { defineConfig } from '@tanstack/react-start/config'
import tsConfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
  tsr: {
    appDirectory: 'src',
  },
  vite: {
    plugins: [
      tsConfigPaths({
        projects: ['./tsconfig.json'],
      }),
    ],
  },
})
```

---

## vite.config.ts

```ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
  ],
  resolve: {
    alias: {
      '~/': `${import.meta.dirname}/src/`,
    },
  },
})
```

---

## Root Layout (`src/routes/__root.tsx`)

```tsx
import { createRootRoute, Outlet, ScrollRestoration } from '@tanstack/react-router'
import { QueryClientProvider } from '@tanstack/react-query'
import { queryClient } from '~/lib/client'
import '~/styles/app.css'

export const Route = createRootRoute({
  component: RootComponent,
})

function RootComponent() {
  return (
    <QueryClientProvider client={queryClient}>
      <ScrollRestoration />
      <Outlet />
    </QueryClientProvider>
  )
}
```

---

## Example Route with Tuyau (`src/routes/posts/index.tsx`)

```tsx
import { createFileRoute } from '@tanstack/react-router'
import { useQuery } from '@tanstack/react-query'
import { api } from '~/lib/client'

export const Route = createFileRoute('/posts/')({
  component: PostsPage,
})

function PostsPage() {
  const { data: posts, isLoading } = useQuery(
    api.posts.index.queryOptions({})
  )

  if (isLoading) return <p>Loading...</p>

  return (
    <ul>
      {posts?.map((post) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  )
}
```

---

## Tailwind CSS v4

The `--add-ons tailwind` flag in `create-tsrouter-app` handles this automatically.

**Manual setup if needed:**

```bash
npm install tailwindcss @tailwindcss/vite
```

`src/styles/app.css`:
```css
@import "tailwindcss";

/* Custom theme tokens (optional) */
@theme {
  --color-primary: oklch(0.5 0.2 250);
}
```

Import in root layout or `src/main.tsx`:
```ts
import './styles/app.css'
```

**No `tailwind.config.js` needed** — Tailwind v4 uses CSS-first configuration.

---

## shadcn/ui Setup

```bash
cd apps/frontend
npx shadcn@latest init
```

Prompts:
- **Which style?** → New York (recommended for modern look)
- **Which base color?** → Neutral (safe default)
- **Use CSS variables?** → Yes

This creates:
- `components.json` — shadcn config
- `src/components/ui/` — component directory
- Updates `src/styles/app.css` with CSS variable theme tokens

### Adding Components

```bash
# Essential UI components
npx shadcn@latest add button
npx shadcn@latest add card
npx shadcn@latest add input
npx shadcn@latest add label
npx shadcn@latest add form
npx shadcn@latest add dropdown-menu
npx shadcn@latest add avatar
npx shadcn@latest add toast
npx shadcn@latest add dialog
npx shadcn@latest add sheet
```

### Using shadcn Components

```tsx
import { Button } from '~/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '~/components/ui/card'
import { Input } from '~/components/ui/input'

export function LoginForm() {
  return (
    <Card className="w-[400px]">
      <CardHeader>
        <CardTitle>Login</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <Input type="email" placeholder="Email" />
        <Input type="password" placeholder="Password" />
        <Button className="w-full">Sign In</Button>
      </CardContent>
    </Card>
  )
}
```

---

## Recommended Additional Packages

```bash
# Form handling (pairs perfectly with shadcn form component)
npm install react-hook-form @hookform/resolvers zod

# Toast notifications
npm install sonner

# Date utilities
npm install date-fns

# Icon library (used by shadcn)
npm install lucide-react

# HTTP client (Tuyau is built on Ky, but useful standalone)
# Already included via @tuyau/core

# State management (lightweight alternative to Redux)
npm install jotai
# or
npm install zustand
```

---

## TypeScript Path Aliases

In `apps/frontend/tsconfig.json`:

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "~/*": ["./src/*"]
    }
  }
}
```

In `vite.config.ts`, add the `vite-tsconfig-paths` plugin to resolve these automatically (included in TanStack Start scaffold).

---

## Frontend Scripts (`apps/frontend/package.json`)

```json
{
  "scripts": {
    "dev": "vinxi dev",
    "build": "vinxi build",
    "start": "vinxi start",
    "typecheck": "tsc --noEmit"
  }
}
```

TanStack Start uses **Vinxi** as its underlying build tool (built on Vite).

---

## Dev Port

TanStack Start defaults to **port 3000**. Configure in `app.config.ts`:

```ts
export default defineConfig({
  server: {
    port: 3000,
  },
})
```