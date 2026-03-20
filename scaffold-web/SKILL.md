---
name: scaffold-web
description: >
  Scaffold a full-stack AdonisJS API + TanStack Start monorepo project from scratch. Use this skill
  whenever the user wants to create a new AdonisJS monorepo project, set up a TanStack Start frontend
  with Tuyau type-safe API client, configure Tailwind CSS, shadcn/ui, or wire up the full-stack
  development environment. Trigger this skill for any of these phrases: "adonis monorepo", "adonis
  api monorepo", "tanstack start adonis", "tuyau setup", "adonis frontend", "api-monorepo starter
  kit", "scaffold adonis project", or whenever the user runs `npm init adonisjs` with `-K=api-monorepo`.
  Also trigger when the user asks about connecting AdonisJS to a React frontend in a monorepo.
model: sonnet
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit, MultiEdit, Glob, Grep, AskUserQuestion
---

# AdonisJS API Monorepo + TanStack Start Skill

Scaffold and wire up a production-ready full-stack monorepo:
- **Backend**: AdonisJS (api-monorepo starter kit) — Node.js 24+, Turborepo, SQLite, dual auth (API tokens + sessions)
- **Frontend**: TanStack Start (React SSR framework) with Tuyau type-safe client, Tailwind CSS v4, shadcn/ui

Read the reference files when needed:
- `references/backend-setup.md` — AdonisJS backend details, adonisrc.ts, package.json exports
- `references/frontend-setup.md` — TanStack Start scaffold, Vite config, routing, Tailwind, shadcn
- `references/tuyau-wiring.md` — Complete Tuyau monorepo wiring (tsconfig, package.json deps, client init, TanStack Query)

---

## Step 0 — Gather Configuration (REQUIRED FIRST)

**Before doing anything**, use `AskUserQuestion` to collect all required information upfront. Do not skip this step or assume defaults.

Ask in two batches of 4 (tool limit):

**Batch 1:**
```
AskUserQuestion([
  {
    question: "What is your project name? (used as folder name and npm scope, e.g. 'my-app' → '@my-app/backend')",
    options: ["my-app", "my-project", "webapp", "fullstack-app"]
    // user will pick Other to type a custom name
  },
  {
    question: "Which package manager are you using?",
    options: ["pnpm (recommended)", "npm", "yarn"]
  },
  {
    question: "Which database do you want to use?",
    options: ["SQLite (default, zero config)", "PostgreSQL", "MySQL"]
  },
  {
    question: "Which authentication strategy will your app use?",
    options: [
      "Both — dual auth (Recommended)",
      "API tokens only (Bearer header — for SPAs, mobile)",
      "Sessions only (cookies — for SSR/traditional web)"
    ]
  }
])
```

**Batch 2:**
```
AskUserQuestion([
  {
    question: "Which shadcn/ui components would you like to install now?",
    options: [
      "Auth-ready — button, input, label, card, sonner, dialog (Recommended)",
      "Minimal — button, input, label, card",
      "Full UI kit — all above + dropdown-menu, avatar, sheet, badge, separator, skeleton",
      "None — I'll add them manually"
    ]
  }
])
```

Store answers as: `$PROJECT_NAME`, `$PKG_MANAGER`, `$DB`, `$AUTH_STRATEGY`, `$SHADCN_COMPONENTS`.

Use `$PKG_MANAGER` in place of `npm`/`npx` throughout:
- pnpm: `pnpm dlx` instead of `npx`, `pnpm install` instead of `npm install`, `pnpm add` instead of `npm install <pkg>`
- npm: `npx`, `npm install`
- yarn: `yarn dlx`, `yarn`

---

## Prerequisites Check

```bash
node --version
```

If below 24, stop:
> "AdonisJS v7 requires Node.js 24+. Your current version is X.X.X. Please upgrade: https://nodejs.org"

---

## Phase 1 — Scaffold the Monorepo

### 1.1 Create the AdonisJS monorepo

The scaffold command always uses `npm init` regardless of the chosen package manager — that's fine, we fix it after.

```bash
npm init adonisjs@latest $PROJECT_NAME -- -K=api-monorepo
```

This creates:
```
$PROJECT_NAME/
├── apps/
│   ├── backend/      # AdonisJS app (Node 24+, SQLite, Lucid ORM, dual auth)
│   └── frontend/     # Placeholder — we replace this
├── package.json      # Root workspaces (npm format)
└── turbo.json        # Turborepo pipeline
```

The backend already has:
- Lucid ORM + SQLite (we switch DB later if needed)
- Session guard + API token guard (dual auth)
- ESLint + Prettier
- Tuyau `@tuyau/core` installed and `generateRegistry` hook in `adonisrc.ts`

**⚠️ If user chose pnpm**: The root `package.json` will have a `"workspaces"` field — pnpm ignores this in favour of `pnpm-workspace.yaml`. Create it now:

```bash
echo 'packages:\n  - "apps/*"' > $PROJECT_NAME/pnpm-workspace.yaml
```

Also update root `package.json`'s `"packageManager"` field:
```json
{ "packageManager": "pnpm@10.0.0" }
```

And move any `pnpm.onlyBuiltDependencies` from app-level `package.json` files to root `package.json`:
```json
{
  "pnpm": {
    "onlyBuiltDependencies": ["better-sqlite3", "esbuild", "lightningcss", "@swc/core"]
  }
}
```

### 1.2 Rename the backend package

The starter kit names the backend `@api-starter-kit/backend`. Read `apps/backend/package.json` and change the name:

```json
{ "name": "@$PROJECT_NAME/backend" }
```

### 1.3 Configure the database

**SQLite** (default): Nothing to do — already configured.

**PostgreSQL**: Edit `apps/backend/config/database.ts`:
1. Change `connection: 'sqlite'` → `connection: 'pg'`
2. Uncomment the `pg` block (it's already there, just commented out):

```ts
pg: {
  client: 'pg',
  connection: {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 5432),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE,
  },
  migrations: {
    naturalSort: true,
    paths: ['database/migrations'],
  },
  debug: app.inDev,
},
```

Then install the pg driver:
```bash
cd $PROJECT_NAME/apps/backend && $PKG_MANAGER add pg
```

**MySQL**: Same pattern — change connection to `'mysql'`, uncomment the mysql block, install `mysql2`.

### 1.4 Replace the frontend placeholder with TanStack Start

```bash
# Clear the placeholder
rm -rf $PROJECT_NAME/apps/frontend/*
rm -rf $PROJECT_NAME/apps/frontend/.*  2>/dev/null || true

# Scaffold TanStack Start (full SSR — do NOT use --router-only)
$PKG_MANAGER dlx @tanstack/cli@latest create frontend \
  --framework react \
  --package-manager $PKG_MANAGER \
  --no-install \
  --no-git \
  --no-examples \
  --no-toolchain \
  --target-dir $PROJECT_NAME/apps/frontend \
  --force
```

> **Important**: Do NOT pass `--router-only` — that creates a plain SPA, not TanStack Start (SSR).
> The generated `package.json` will include `@tanstack/react-start` and `vite.config.ts` will use `tanstackStart()`.

**⚠️ Verify**: Check the scaffold produced TanStack Start, not just TanStack Router:

```bash
grep '@tanstack/react-start' $PROJECT_NAME/apps/frontend/package.json
```

If that line is missing, the `--router-only` flag was accidentally used. Re-run without it.

Also verify routes:
```bash
ls $PROJECT_NAME/apps/frontend/src/routes/
```
Expected: `__root.tsx`, `index.tsx`.

---

## Phase 2 — Wire Tuyau (Type-safe API Client)

Use `$PROJECT_NAME` as the npm scope. Replace `@my-app` with `@$PROJECT_NAME` everywhere below.

### 2.1 Backend — Add registry exports

Read `apps/backend/package.json`, then add the `exports` field:

```json
{
  "name": "@$PROJECT_NAME/backend",
  "exports": {
    "./registry": "./.adonisjs/client/registry/index.ts",
    "./data": "./.adonisjs/client/data.d.ts"
  }
}
```

### 2.2 Frontend — Add backend workspace dep + Tuyau packages

Read `apps/frontend/package.json`, then add to `dependencies`:

```json
{
  "name": "@$PROJECT_NAME/frontend",
  "dependencies": {
    "@$PROJECT_NAME/backend": "workspace:*",
    "@tuyau/core": "^1.0.0",
    "@tuyau/react-query": "^1.0.0",
    "@tanstack/react-query": "^5.0.0"
  }
}
```

> Use `"workspace:*"` for pnpm, `"*"` for npm/yarn.

### 2.3 Frontend tsconfig.json

Read the existing `apps/frontend/tsconfig.json`, then rewrite it preserving all existing `compilerOptions` but replacing `include`/`exclude` and adding `experimentalDecorators`:

```json
{
  "include": [
    "**/*.ts",
    "**/*.tsx",
    "../backend/**/*.ts",
    "../backend/.adonisjs/**/*.ts"
  ],
  "exclude": [
    "node_modules",
    "../backend/build",
    "../backend/node_modules"
  ],
  "compilerOptions": {
    "experimentalDecorators": true,
    // ... all existing compilerOptions fields preserved
  }
}
```

### 2.4 Create the Tuyau client

Create `apps/frontend/src/lib/client.ts`:

```ts
import { createTuyau } from '@tuyau/core/client'
import { registry } from '@$PROJECT_NAME/backend/registry'
import { QueryClient } from '@tanstack/react-query'
import { createTuyauReactQueryClient } from '@tuyau/react-query'

export const queryClient = new QueryClient()

export const client = createTuyau({
  baseUrl: import.meta.env.VITE_API_URL || 'http://localhost:3333',
  registry,
  headers: { Accept: 'application/json' },
  hooks: {
    beforeRequest: [
      (request) => {
        const token = localStorage.getItem('auth_token')
        if (token) {
          request.headers.set('Authorization', `Bearer ${token}`)
        }
      },
    ],
  },
})

export const api = createTuyauReactQueryClient({ client })
```

### 2.5 Wrap app with QueryClientProvider

Read `apps/frontend/src/routes/__root.tsx` first. TanStack Start uses a `shellComponent` pattern — the root renders the full HTML document. The `QueryClientProvider` must wrap content inside the `<body>`, NOT the entire `<html>` element.

Add the import at the top:
```tsx
import { QueryClientProvider } from '@tanstack/react-query'
import { queryClient } from '../lib/client'
```

Then wrap only the body content:
```tsx
function RootDocument({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <HeadContent />
      </head>
      <body>
        <QueryClientProvider client={queryClient}>
          {children}
          {/* devtools, footer, etc. */}
        </QueryClientProvider>
        <Scripts />
      </body>
    </html>
  )
}
```

> Keep `<Scripts />` outside the `QueryClientProvider` — it must be a direct child of `<body>`.

### 2.6 Generate the initial registry

```bash
cd $PROJECT_NAME/apps/backend && node ace tuyau:generate
```

If this fails with "missing `.adonisjs/client/`", the assembler hook hasn't run yet. Start the backend dev server once to trigger it:
```bash
node ace serve --hmr
# Wait for "Server started" then Ctrl+C
node ace tuyau:generate
```

---

## Phase 3 — Tailwind CSS v4

TanStack Start scaffolded by `@tanstack/cli` already includes Tailwind v4 via `@tailwindcss/vite` — no manual setup needed.

Verify `vite.config.ts` has:
```ts
import tailwindcss from '@tailwindcss/vite'
// ...
plugins: [tailwindcss(), tanstackStart(), ...]
```

And `src/styles.css` starts with:
```css
@import "tailwindcss";
```

If either is missing, add them manually.

---

## Phase 4 — shadcn/ui

### 4.1 Init shadcn

Use `--template start` so shadcn knows this is TanStack Start (SSR), not a plain Vite SPA.
Use `--preset nova` for the Nova preset (Geist font, Lucide icons) — no interactive prompts needed.

```bash
cd $PROJECT_NAME/apps/frontend
$PKG_MANAGER dlx shadcn@latest init --template start --preset nova -y
```

Verify it detected TanStack Start: output should say `✔ Verifying framework. Found TanStack Start.`

> The `--style` and `--base-color` flags no longer exist in shadcn v4+. Use `--preset` instead.
> Available presets: `nova` (recommended), `vega`, `maia`, `lyra`, `mira`.

### 4.2 Add components

Install based on `$SHADCN_COMPONENTS` chosen in Step 0.

> **Note**: `toast` is deprecated — use `sonner` instead.

**Auth-ready:**
```bash
$PKG_MANAGER dlx shadcn@latest add button input label card sonner dialog -y
```

**Minimal:**
```bash
$PKG_MANAGER dlx shadcn@latest add button input label card -y
```

**Full UI kit:**
```bash
$PKG_MANAGER dlx shadcn@latest add button input label card sonner dialog dropdown-menu avatar sheet badge separator skeleton -y
```

Components land in `src/components/ui/`.

---

## Phase 5 — Turborepo Pipeline

Read `turbo.json`. Ensure it has `.output/**` in build outputs (TanStack Start writes there):

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "dev": {
      "cache": false,
      "persistent": true
    },
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".output/**", "build/**", ".adonisjs/**"]
    },
    "typecheck": {
      "dependsOn": ["^build"]
    }
  }
}
```

---

## Phase 6 — Environment Variables

### Backend (`apps/backend/.env`)

The starter kit creates `.env` automatically with `APP_KEY` already set. Read it and ensure these are present:

```env
TZ=UTC
PORT=3333
HOST=localhost
LOG_LEVEL=info
APP_KEY=<already generated>
NODE_ENV=development
SESSION_DRIVER=cookie
```

**PostgreSQL** — append:
```env
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=
DB_DATABASE=$PROJECT_NAME
```

**MySQL** — append:
```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_DATABASE=$PROJECT_NAME
```

### Frontend (`apps/frontend/.env`)

```env
VITE_API_URL=http://localhost:3333
```

---

## Phase 7 — CORS Configuration

The starter kit's `apps/backend/config/cors.ts` already uses:
```ts
origin: app.inDev ? true : [],
```
This allows all origins in development — no changes needed for local dev.

For production, update the `origin` array with your deployed frontend URL.

---

## Phase 8 — Install All Dependencies & Verify

```bash
cd $PROJECT_NAME

# Install all workspace deps
$PKG_MANAGER install

# Verify backend name matches frontend dependency
grep '"name"' apps/backend/package.json
grep '@$PROJECT_NAME/backend' apps/frontend/package.json
```

**⚠️ Confirmation point**: Present a summary and ask:

```
AskUserQuestion([{
  question: "Scaffold complete! What would you like to do next?",
  options: [
    "Run database migrations first (node ace migration:run)",
    "Start the dev servers now (pnpm dev)",
    "Show me the project structure overview",
    "Nothing — I'll take it from here"
  ]
}])
```

If **Run database migrations**:
```bash
cd apps/backend && node ace migration:run
```
Then ask again about dev servers.

If **Start dev servers**:
```bash
$PKG_MANAGER dev
```
Inform: Backend → http://localhost:3333, Frontend → http://localhost:3000

---

## Running the Monorepo

```bash
$PKG_MANAGER dev
```

- Backend: http://localhost:3333
- Frontend: http://localhost:3000

Regenerate types after backend route changes:
```bash
cd apps/backend && node ace tuyau:generate
```

---

## Making Type-safe API Calls

```tsx
// Using TanStack Query (recommended)
import { useQuery } from '@tanstack/react-query'
import { api } from '../lib/client'

function Posts() {
  const { data, isLoading } = useQuery(api.posts.index.queryOptions({}))
  return isLoading ? <p>Loading…</p> : <ul>{data?.map(p => <li key={p.id}>{p.title}</li>)}</ul>
}

// Direct call
import { client } from '../lib/client'

const post = await client.api.posts.store({
  body: { title: 'Hello', content: 'World' }
})
```

---

## Common Issues

| Problem | Fix |
|---|---|
| `Cannot find module '@$PROJECT_NAME/backend/registry'` | Run `node ace tuyau:generate` in backend, then `$PKG_MANAGER install` at root |
| CORS errors in production | Update `config/cors.ts` origin array with your deployed frontend URL |
| Type errors about decorators | Ensure `"experimentalDecorators": true` is in `apps/frontend/tsconfig.json` |
| `.adonisjs/client` missing | Run `node ace serve --hmr` once to trigger the assembler hook, then `node ace tuyau:generate` |
| shadcn components not styled | Verify `@import "tailwindcss"` is in `src/styles.css` and the CSS file is imported in `__root.tsx` |
| `node --version` < 24 | AdonisJS v7 requires Node 24+. Use nvm: `nvm install 24 && nvm use 24` |
| pnpm can't find workspace packages | Ensure `pnpm-workspace.yaml` exists at root with `apps/*`; run `pnpm install` from root |
| shadcn detected as Vite not Start | Ensure you did NOT use `--router-only` when scaffolding; `@tanstack/react-start` must be in `package.json` |
| `toast` component error | Use `sonner` instead — `toast` is deprecated in shadcn v4 |
| Frontend scaffold missing `@tanstack/react-start` | Re-scaffold without `--router-only` flag |
| pnpm warns about `workspaces` field | Create `pnpm-workspace.yaml` — pnpm ignores the npm `workspaces` field |

---

## Suggested Project Structure (Final)

```
$PROJECT_NAME/
├── apps/
│   ├── backend/
│   │   ├── app/
│   │   │   ├── controllers/
│   │   │   ├── models/
│   │   │   ├── middleware/
│   │   │   └── validators/
│   │   ├── config/
│   │   │   ├── cors.ts         ← inDev allows all origins
│   │   │   └── database.ts     ← pg/sqlite/mysql connection
│   │   ├── start/routes.ts
│   │   ├── adonisrc.ts         ← generateRegistry hook
│   │   ├── package.json        ← name: @$PROJECT_NAME/backend, exports ./registry
│   │   ├── .env                ← DB_* vars, APP_KEY
│   │   └── .adonisjs/          ← generated Tuyau types (commit this!)
│   └── frontend/
│       ├── src/
│       │   ├── components/ui/  ← shadcn components
│       │   ├── lib/client.ts   ← Tuyau + QueryClient
│       │   ├── routes/
│       │   │   ├── __root.tsx  ← shellComponent with QueryClientProvider
│       │   │   └── index.tsx
│       │   └── styles.css      ← @import "tailwindcss" + shadcn vars
│       ├── tsconfig.json       ← experimentalDecorators + includes backend types
│       ├── vite.config.ts      ← tanstackStart() + tailwindcss() plugins
│       └── .env                ← VITE_API_URL
├── pnpm-workspace.yaml         ← pnpm only (apps/*)
├── package.json                ← packageManager: pnpm, onlyBuiltDependencies
└── turbo.json                  ← .output/** in build outputs
```
