# Backend Setup Reference — AdonisJS api-monorepo

## What the starter kit gives you

Running `npm init adonisjs@latest <name> -- -K=api-monorepo` scaffolds:

- **Turborepo** monorepo at root
- **AdonisJS v7** backend in `apps/backend/`
- **Empty** `apps/frontend/` placeholder with a minimal `package.json`
- Root `package.json` with npm workspaces
- Root `turbo.json` with `dev` and `build` tasks

### Backend features (pre-configured)
- Lucid ORM with SQLite (swap to PostgreSQL/MySQL easily)
- Dual authentication: session guard + opaque API tokens guard
- `@tuyau/core` installed and `generateRegistry` hook active
- ESLint + Prettier
- Vite 7 for asset bundling
- Node.js 24+ required (uses `crypto.randomUUID`, `util.parseEnv`, etc.)

---

## adonisrc.ts — Key Parts

```ts
import { indexEntities } from '@adonisjs/core'
import { defineConfig } from '@adonisjs/core/app'
import { generateRegistry } from '@tuyau/core/hooks'

export default defineConfig({
  hooks: {
    init: [
      // Indexes models + transformers for type generation
      indexEntities({ transformers: { enabled: true } }),
      // Generates .adonisjs/client/registry/index.ts on every dev start
      generateRegistry(),
    ],
  },
})
```

The `generateRegistry` hook fires automatically when you run `node ace serve --hmr` (dev mode). It writes to `.adonisjs/client/` — **commit this directory**.

---

## Backend package.json — Exports

After scaffolding, **add these exports** so the frontend workspace can import types:

```json
{
  "name": "@my-app/backend",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "exports": {
    "./registry": "./.adonisjs/client/registry/index.ts",
    "./data": "./.adonisjs/client/data.d.ts"
  },
  "scripts": {
    "dev": "node ace serve --hmr",
    "build": "node ace build",
    "start": "node bin/server.js"
  }
}
```

Replace `@my-app` with your actual monorepo package scope (e.g., `@acme`, `@company`, or just the project name).

---

## Authentication Endpoints (pre-built)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/auth/signup` | Create account |
| POST | `/api/v1/auth/login` | Login (returns token) |
| DELETE | `/api/v1/auth/logout` | Logout |
| GET | `/api/v1/auth/me` | Current user |

Both session cookies and Bearer token auth work on all protected routes.

---

## Database

Default: SQLite at `apps/backend/tmp/db.sqlite`

Migrations already created for `users` table.

To run migrations:
```bash
cd apps/backend
node ace migration:run
```

To switch to PostgreSQL:
```bash
node ace configure @adonisjs/lucid
# Select PostgreSQL, update DB_* env vars
```

---

## Generating the Registry Manually

If types seem stale:
```bash
cd apps/backend
node ace tuyau:generate
```

This regenerates `.adonisjs/client/registry/index.ts` based on current routes, controllers, and validators.

---

## Adding Controllers and Routes

```bash
# Make a controller
node ace make:controller posts

# Register route in start/routes.ts
import router from '@adonisjs/core/services/router'
import { controllers } from '#generated/controllers'

router.resource('posts', controllers.Posts).apiOnly()
```

Route names are auto-derived: `posts.index`, `posts.show`, `posts.store`, `posts.update`, `posts.destroy`.

---

## Transformers (for type-safe responses)

Always return data through transformers — returning Lucid models directly loses type info in Tuyau:

```ts
// app/transformers/post_transformer.ts
import { BaseTransformer } from '@adonisjs/core/transformers'
import type Post from '#models/post'

export default class PostTransformer extends BaseTransformer<Post> {
  toObject() {
    return {
      id: this.model.id,
      title: this.model.title,
      content: this.model.content,
      createdAt: this.model.createdAt,
    }
  }
}

// In controller:
async show({ params, serialize }: HttpContext) {
  const post = await Post.findOrFail(params.id)
  return serialize(PostTransformer.transform(post))
}
```