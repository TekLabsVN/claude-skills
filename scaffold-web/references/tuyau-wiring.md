# Tuyau Wiring Reference — Monorepo Setup

Complete guide to connecting AdonisJS backend (type generator) to TanStack Start frontend (consumer) via Tuyau.

---

## How Tuyau Works in a Monorepo

1. **Backend**: `@tuyau/core` is installed. The `generateRegistry` assembler hook runs on every dev start and generates `.adonisjs/client/registry/index.ts` — a fully typed map of all your AdonisJS routes.
2. **Backend exports** this registry via `package.json` exports.
3. **Frontend** depends on the backend as a workspace package (`"@my-app/backend": "*"`), imports the registry, and creates a type-safe client.
4. **TypeScript** in the frontend includes backend source files to resolve the cross-package types at compile time.

---

## Step-by-Step Wiring

### Step 1: Backend package.json name + exports

`apps/backend/package.json`:
```json
{
  "name": "@my-app/backend",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "exports": {
    ".": "./bin/server.ts",
    "./registry": "./.adonisjs/client/registry/index.ts",
    "./data": "./.adonisjs/client/data.d.ts"
  }
}
```

> Replace `@my-app` with your actual scope/name consistently across all files.

### Step 2: Frontend package.json — depend on backend workspace

`apps/frontend/package.json`:
```json
{
  "name": "@my-app/frontend",
  "private": true,
  "type": "module",
  "dependencies": {
    "@my-app/backend": "*",
    "@tuyau/core": "^1.0.0",
    "@tuyau/react-query": "^1.0.0",
    "@tanstack/react-query": "^5.0.0",
    "@tanstack/react-query-devtools": "^5.0.0"
  }
}
```

The `"*"` version resolves to the local workspace package. Run `npm install` at the monorepo root after editing.

### Step 3: Frontend tsconfig.json

`apps/frontend/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "experimentalDecorators": true,
    "skipLibCheck": true,
    "baseUrl": ".",
    "paths": {
      "~/*": ["./src/*"]
    }
  },
  "include": [
    "./**/*.ts",
    "./**/*.tsx",
    "../backend/**/*.ts",
    "../backend/.adonisjs/**/*.ts"
  ],
  "exclude": [
    "node_modules",
    "../backend/build",
    "../backend/node_modules"
  ]
}
```

### Step 4: Backend adonisrc.ts (verify hook is present)

`apps/backend/adonisrc.ts` — should already have this from the starter kit:
```ts
import { indexEntities } from '@adonisjs/core'
import { defineConfig } from '@adonisjs/core/app'
import { generateRegistry } from '@tuyau/core/hooks'

export default defineConfig({
  hooks: {
    init: [
      indexEntities({ transformers: { enabled: true } }),
      generateRegistry(),
    ],
  },
  // ... rest of config
})
```

### Step 5: Tuyau client + QueryClient

`apps/frontend/src/lib/client.ts`:
```ts
import { createTuyau } from '@tuyau/core/client'
import { registry } from '@my-app/backend/registry'
import { QueryClient } from '@tanstack/react-query'
import { createTuyauReactQueryClient } from '@tuyau/react-query'

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60, // 1 minute
      retry: 1,
    },
  },
})

export const client = createTuyau({
  baseUrl: import.meta.env.VITE_API_URL || 'http://localhost:3333',
  registry,
  headers: { Accept: 'application/json' },
  credentials: 'include', // For session-based auth (sends cookies)
  hooks: {
    beforeRequest: [
      (request) => {
        // For token-based auth, attach Bearer token
        const token = localStorage.getItem('auth_token')
        if (token) {
          request.headers.set('Authorization', `Bearer ${token}`)
        }
      },
    ],
    afterResponse: [
      async (_request, _options, response) => {
        if (response.status === 401) {
          // Handle unauthorized — redirect to login or clear token
          localStorage.removeItem('auth_token')
        }
      },
    ],
  },
})

// TanStack Query + Tuyau integration
export const api = createTuyauReactQueryClient({ client })

// Type helpers
export type TuyauClient = typeof client
export type ApiClient = typeof api
```

---

## Usage Patterns

### Queries (read data)

```tsx
import { useQuery } from '@tanstack/react-query'
import { api } from '~/lib/client'

// Simple query
function PostsList() {
  const { data, isLoading, error } = useQuery(
    api.posts.index.queryOptions({})
  )
  // ...
}

// With query params (typed!)
function PostsFiltered() {
  const { data } = useQuery(
    api.posts.index.queryOptions({
      query: { page: 1, limit: 10, status: 'published' }
    })
  )
}

// With route params
function PostDetail({ id }: { id: string }) {
  const { data } = useQuery(
    api.posts.show.queryOptions({ params: { id } })
  )
}
```

### Mutations (write data)

```tsx
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { api, queryClient } from '~/lib/client'

function CreatePost() {
  const qc = useQueryClient()
  
  const { mutate, isPending } = useMutation(
    api.posts.store.mutationOptions({
      onSuccess: () => {
        // Invalidate cache so list refreshes
        qc.invalidateQueries({ queryKey: ['posts'] })
      },
    })
  )

  return (
    <button
      disabled={isPending}
      onClick={() => mutate({ body: { title: 'New Post', content: '...' } })}
    >
      Create
    </button>
  )
}
```

### Direct client calls (no Query)

```ts
import { client } from '~/lib/client'

// Await directly
const result = await client.api.auth.login({
  body: { email: 'user@example.com', password: 'secret' }
})

// With safe() — no throw, returns [data, error]
const [data, error] = await client.api.posts.show({
  params: { id: '1' }
}).safe()

if (error?.isStatus(404)) {
  console.log('Post not found:', error.response.message)
}
```

### Authentication flow example

```tsx
import { client } from '~/lib/client'
import { useNavigate } from '@tanstack/react-router'

function useLogin() {
  const navigate = useNavigate()
  
  return async (email: string, password: string) => {
    const [data, error] = await client.api.auth.login({
      body: { email, password }
    }).safe()
    
    if (error) {
      throw new Error('Login failed')
    }
    
    // Store token for API token guard
    if (data.token) {
      localStorage.setItem('auth_token', data.token.value)
    }
    
    navigate({ to: '/dashboard' })
  }
}
```

---

## Cache Key Management

Tuyau + TanStack Query automatically generates cache keys from route names. To invalidate manually:

```ts
// Invalidate all posts queries
queryClient.invalidateQueries({ queryKey: ['posts'] })

// Invalidate specific post
queryClient.invalidateQueries({ queryKey: ['posts', 'show', { params: { id: '1' } }] })
```

---

## Type Helpers

Extract request/response types for use in components:

```ts
import type { Route } from '@tuyau/core/types'

// Infer types from route names
type PostBody = Route.Body<'posts.store'>
type PostResponse = Route.Response<'posts.show'>
type PostsQuery = Route.Query<'posts.index'>
```

---

## Troubleshooting

### `Cannot find module '@my-app/backend/registry'`
1. Make sure backend `package.json` has the `./registry` export
2. Run `node ace tuyau:generate` in `apps/backend/`
3. Run `npm install` at monorepo root to link workspace packages
4. Restart TypeScript server in your IDE

### `Type 'unknown' on API responses`
- You're returning Lucid models directly. Use transformers instead (see backend-setup.md)
- Always call `request.validateUsing()` in controllers

### Types are stale after route changes
```bash
cd apps/backend
node ace tuyau:generate
```
Then restart the dev server.

### CORS errors in browser
- Check `apps/backend/config/cors.ts` allows `http://localhost:3000`
- Add `credentials: true` to CORS config
- Add `credentials: 'include'` to the Tuyau client

### `experimentalDecorators` error
Add to `apps/frontend/tsconfig.json`:
```json
{ "compilerOptions": { "experimentalDecorators": true } }
```