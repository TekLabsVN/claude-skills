---
name: web-to-mobile
metadata:
  version: 1.1.0
description: >
  Converts an existing web platform into a production-ready Expo (React Native) mobile
  app by deeply analyzing the repo, mapping all APIs and user flows to mobile screens,
  generating a spec document for owner review, then scaffolding the full project with
  real auth wired up and detailed TODO markers for all other API calls — then wiring
  them all up on a final GO. Use this skill whenever the user wants to build a mobile
  app from an existing web platform, says "build a mobile version of our app", "create
  an Expo app from our backend", "convert our platform to mobile", "spin up an app for
  our existing APIs", or wants to build any mobile companion — even if they don't say
  "web-to-mobile" explicitly. Always reach for this skill when there's an existing
  web/backend repo and the goal is a new mobile app.
---

## Pre-flight — Version Check

Run this silently before anything else. Do NOT mention it to the user unless the skill is outdated.

**Step 1 — Fetch the latest version manifest:**

Use WebFetch to GET `https://raw.githubusercontent.com/TekLabsVN/Teklabs-claude-custom-skills/main/versions.json`

- If the fetch fails (network error, offline), skip this entire phase silently and continue.
- If it succeeds, parse the JSON and read `skills["web-to-mobile"]` as `LATEST_VERSION`.

**Step 2 — Compare versions:**

The current installed version of this skill is defined in the frontmatter above: `metadata.version: 1.1.0` — call this `CURRENT_VERSION`.

Compare `CURRENT_VERSION` with `LATEST_VERSION` using semantic versioning. If they are equal, skip the rest of this phase silently.

**Step 3 — Prompt the user (only if outdated):**

If `LATEST_VERSION` is newer than `CURRENT_VERSION`, use AskUserQuestion to ask:

> "The **web-to-mobile** skill you're using is **v{CURRENT_VERSION}**, but **v{LATEST_VERSION}** is available. Auto-update now? (yes / no — update will overwrite `~/.claude/skills/web-to-mobile/SKILL.md`)"

**Step 4 — Auto-update (only if user says yes):**

1. Use WebFetch to GET `https://raw.githubusercontent.com/TekLabsVN/Teklabs-claude-custom-skills/main/web-to-mobile/SKILL.md`
2. Use Write to overwrite `~/.claude/skills/web-to-mobile/SKILL.md` with the fetched content.
3. Tell the user: "✓ web-to-mobile skill updated to v{LATEST_VERSION}. Please re-run `/web-to-mobile` to use the latest version." Then STOP — do not continue with the outdated skill logic.

If the user says no, continue with the current skill as-is.

---

# Web-to-Mobile

You're converting an existing web platform into a native Expo app. The backend already
works — your job is to understand it deeply, map it to mobile, and scaffold an Expo
project that plugs into the existing APIs. Don't rebuild anything that already exists.

Work in **three phases** with explicit owner checkpoints. Never advance without a **GO**.

---

## Phase 1: Deep Codebase Analysis

Read the web project before writing anything. You're building a mental model of the
entire system so the spec you produce reflects reality, not guesses.

### 1A. Identify the Stack

Check `package.json`, `composer.json`, `pyproject.toml`, `requirements.txt`, or
equivalent to understand the framework and language. Common patterns:

- **Next.js** — look for `/pages/api/` or `/app/api/` (App Router), `/pages/` or `/app/` for UI
- **Express/Node** — `app.use()` calls in entry file, `/routes/` or `/src/routes/`
- **NestJS** — `@Controller()` decorators in `*.controller.ts` files
- **Laravel** — `routes/api.php`, `app/Http/Controllers/`
- **Django** — `urls.py` files, `views.py`
- **FastAPI/Flask** — router registration in main file

### 1B. API Inventory

Find every callable API endpoint. For each one, read the actual handler — don't just
note the path, understand what it does:

- HTTP method + full path
- What it does (infer from handler logic, not just the name)
- Auth requirement: public, requires token, requires specific role?
- Request body shape (if POST/PUT/PATCH)
- Response shape — especially what the mobile app will need to display

Group by domain (auth, users, products, orders, etc.) — this maps naturally to how
you'll organize `src/api/` files later.

### 1C. Auth Configuration

This is critical — get it right before writing the spec. Look for:

- **JWT**: middleware that validates Bearer tokens, look for `jsonwebtoken`, `jose`, `jwt-decode`
- **OAuth**: next-auth config, passport.js strategies, OAuth provider names (Google, GitHub, Apple, etc.)
- **Sessions**: express-session, cookie-session, database session stores
- **Token issuance**: where are tokens created and what's in the payload?
- **Protected route pattern**: how does the web app gate authenticated routes?

Note the exact Authorization header format the backend expects (Bearer, Token, etc.)
and whether refresh tokens exist.

### 1D. User-Facing Pages → Proposed Screens

For each page/view in the web app, ask: does this make sense on mobile? Map to screens:

- Skip admin-only pages unless the mobile app is an admin tool
- Skip pages that are pure web-platform things (OAuth callback pages, etc.)
- Group related pages into tabs or stack navigators
- Identify what data each page loads and from which endpoints

### 1E. Shared Types

Look for TypeScript interfaces, Prisma schemas, OpenAPI/Swagger specs, or Zod schemas.
These can be adapted for the mobile app's `src/types/` directory, saving a lot of work.

### 1F. Design System Analysis

The mobile app must **look and feel like the web app** — same brand, same visual language.
Read the web app's styling to extract its design system:

**Colors** — look in:
- Tailwind config (`tailwind.config.js/ts`) — `theme.extend.colors` is your primary source
- CSS custom properties (`globals.css`, `variables.css`, `theme.css`) — `--color-*`, `--primary`, etc.
- Design token files (`tokens.ts`, `constants/colors.ts`, `styles/colors.ts`)
- Component files — recurring hex values or named color references

Extract: primary, secondary, accent, background, surface/card, border, text (primary/muted/disabled), destructive/error, success, warning colors. Also check dark mode variants.

**Typography** — look in:
- `tailwind.config.js` for custom font families
- `_app.tsx` / `layout.tsx` for font imports (Google Fonts, next/font)
- `globals.css` for `font-family` on `body` or `:root`

Extract: font family names, heading sizes (h1–h4), body size, small/caption size, font weights used.

**Spacing & Radius** — check `tailwind.config.js` for custom spacing and border-radius overrides. Note the base scale if it differs from Tailwind defaults.

**Component Patterns** — skim 3–5 core UI components (buttons, cards, inputs, modals). Note:
- Button shape (pill, rounded, square) and fill style (solid, outline, ghost)
- Card style (shadow, border, flat)
- Input style (underline, bordered, filled)
- Any consistent shadow / elevation pattern

**Dark Mode** — does the web app have dark mode? (`dark:` classes, `ColorScheme` context, `next-themes`). Note default mode.

**Brand Assets** — check `/public/` or `/assets/` for logo files (SVG preferred).

---

## Phase 2: Generate the Mobile Spec

Save as **`MOBILE_APP_SPEC.md`** in the web project root (or `docs/` if that folder exists).

Use this structure:

```markdown
# Mobile App Spec — [App Name]
Generated: [date]
Web repo: [path or name]

## App Overview
[2–3 sentences describing what the mobile app does for users]

## User Stories
| # | As a user I want to… | Web route | Mobile screen | Priority |
|---|---|---|---|---|
| 1 | Log in with Google | /auth/login | LoginScreen | P0 |
| 2 | View my dashboard | /dashboard | HomeScreen | P0 |
...

## API Inventory
| Method | Endpoint | Auth? | Purpose | Mobile screen(s) |
|--------|----------|-------|---------|-----------------|
| POST | /api/auth/login | No | Exchange credentials for JWT | LoginScreen |
| GET | /api/user/me | Bearer | Get current user profile | ProfileScreen |
...

## Auth Strategy
**Web uses:** [what you found — e.g., "next-auth with Google OAuth, JWT session tokens"]
**Mobile will use:** expo-secure-store for token persistence + [OAuth/JWT approach]
**Token flow:**
1. [Describe login → token issuance]
2. [Describe token storage: SecureStore]
3. [Describe how token attaches to requests: axios interceptor]
4. [Describe 401 handling: logout + redirect to login]
**OAuth note:** [If OAuth — Expo AuthSession handles the redirect, app.json scheme needed]

## Proposed Navigation Structure
[Describe the tab/stack layout. Example:]
- Root: Auth gate (checks SecureStore on launch)
  - (auth) stack: LoginScreen → [RegisterScreen if applicable]
  - (app) tabs:
    - Home tab: HomeScreen → DetailScreen
    - Profile tab: ProfileScreen → EditProfileScreen
    - [other tabs]

## Tech Stack
- Expo SDK (latest) with TypeScript
- Expo Router v3 (file-based navigation, mirrors web mental model)
- NativeWind v4 (Tailwind CSS for React Native)
- Zustand (auth store + any global state)
- Axios (HTTP client with auth interceptor)
- TanStack Query v5 (server state, caching, loading/error)
- expo-secure-store (secure token persistence)
- expo-auth-session (if OAuth)

## Design System

**Source:** [where you found the values — e.g., "tailwind.config.ts + globals.css"]

### Colors
| Role | Web value | NativeWind class / hex |
|------|-----------|----------------------|
| Primary | `#6366f1` | `bg-indigo-500` / `#6366f1` |
| Background | `#ffffff` / `#0f0f0f` | `bg-white` / `bg-zinc-950` |
| Surface/Card | `#f4f4f5` | `bg-zinc-100` |
| Text primary | `#18181b` | `text-zinc-900` |
| Text muted | `#71717a` | `text-zinc-500` |
| Border | `#e4e4e7` | `border-zinc-200` |
| Destructive | `#ef4444` | `text-red-500` |
[add rows for your actual values]

### Typography
- **Font family:** [e.g., Inter, System default]
- **Heading (h1):** [size + weight — e.g., 28px bold]
- **Heading (h2):** [size + weight]
- **Body:** [size + weight — e.g., 16px regular]
- **Caption/Small:** [size + weight — e.g., 12px regular]

### Component Patterns
- **Buttons:** [e.g., "pill shape, solid primary fill, ghost variant for secondary actions"]
- **Cards:** [e.g., "white bg, 1px zinc-200 border, 12px radius, subtle shadow"]
- **Inputs:** [e.g., "bordered, zinc-200 border, 8px radius, zinc-100 bg"]
- **Dark mode:** [supported / not supported / default dark]

## Items Needing Owner Input
- [ ] API base URL for mobile (dev/staging/production)
- [ ] App name and bundle ID (e.g. com.yourcompany.appname)
- [ ] OAuth redirect scheme (e.g. myapp://) — needed for Expo AuthSession
- [ ] Features to exclude from mobile MVP (if any)
- [ ] Any push notification requirements?
- [ ] Confirm design system matches expectations (see Design System section above)
```

After saving, tell the user:

> "I've saved the spec to `MOBILE_APP_SPEC.md`. Please review the user stories and API
> inventory — add anything missing, adjust priorities, and fill in the 'Items Needing
> Owner Input' section. When you're happy with it, say **GO** and I'll scaffold the project."

**Stop here. Wait for explicit GO.**

---

## Phase 3: Scaffold the Expo Project

Once the owner approves, build the project.

### 3A. Create the App

```bash
npx create-expo-app@latest [app-name] --template blank-typescript
```

Derive `[app-name]` from the web project (e.g. `my-platform` → `my-platform-app`).

### 3B. Install Dependencies

```bash
cd [app-name]
npx expo install expo-router expo-secure-store expo-constants expo-auth-session expo-web-browser
npx expo install react-native-safe-area-context react-native-screens react-native-gesture-handler
npm install axios zustand @tanstack/react-query
npm install nativewind tailwindcss
```

Configure NativeWind v4:
- Add `nativewind/babel` to `babel.config.js` plugins
- Add NativeWind preset to `tailwind.config.js`
- Create `global.css` with `@tailwind base; @tailwind components; @tailwind utilities;`
- Import `global.css` in `app/_layout.tsx`
- Update `metro.config.js` to enable CSS support

### 3C. Folder Structure

```
app/
  (auth)/
    _layout.tsx        # Stack navigator for auth screens
    login.tsx
    register.tsx       # Only if registration exists in web app
  (app)/
    _layout.tsx        # Tab navigator (or stack if no tabs needed)
    index.tsx          # Home/Dashboard
    [other screens]    # One file per screen from the spec
  _layout.tsx          # Root layout: QueryClientProvider + auth gate
  +not-found.tsx

src/
  api/
    client.ts          # Axios instance with base URL + auth interceptor
    auth.ts            # Auth API functions (login, logout, refresh)
    [feature].ts       # One file per API domain from the inventory
  store/
    auth.ts            # Zustand: token, user, isAuthenticated, login(), logout()
  types/
    index.ts           # Shared types adapted from web project
    [feature].ts       # Feature-specific types
  theme.ts             # Design tokens — colors, typography, spacing, radius
  components/
    [shared UI components as needed]
  hooks/
    useAuth.ts         # Convenience hook wrapping auth store

.env.example           # API_BASE_URL, OAUTH_CLIENT_ID, etc.
BUILD_NOTES.md         # All TODOs, setup steps, what's left
```

### 3D. Fully Implement These Files (no TODOs)

These are the foundation — implement them completely before touching screens.

**`src/theme.ts`** — Design token constants derived from the web app's design system (Phase 1F).
This is the single source of truth for all visual values in the mobile app.

```ts
export const colors = {
  primary: '#6366f1',       // match web primary exactly
  background: '#ffffff',
  surface: '#f4f4f5',
  border: '#e4e4e7',
  text: '#18181b',
  textMuted: '#71717a',
  destructive: '#ef4444',
  // ... all values from spec Design System section
  dark: {                   // only if web app supports dark mode
    background: '#0f0f0f',
    surface: '#18181b',
    // ...
  }
};

export const typography = {
  fontFamily: 'Inter_400Regular',   // match web font
  fontFamilyBold: 'Inter_700Bold',
  h1: { fontSize: 28, fontWeight: '700' as const },
  h2: { fontSize: 22, fontWeight: '600' as const },
  body: { fontSize: 16, fontWeight: '400' as const },
  caption: { fontSize: 12, fontWeight: '400' as const },
};

export const radius = {
  sm: 6,
  md: 10,
  lg: 16,
  full: 9999,
};

export const shadows = {
  card: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 2,
  },
};
```

Fill in values from the spec — don't use hardcoded values in screen files. Reference `theme.ts`
everywhere so the entire app can be rebranded by editing one file.

**`tailwind.config.js`** — Register all custom colors from the web app so NativeWind classes
like `bg-primary` work everywhere:
```js
theme: {
  extend: {
    colors: {
      primary: '#6366f1',   // must match theme.ts exactly
      // ... all custom colors
    }
  }
}
```

**`src/api/client.ts`**
```ts
import axios from 'axios';
import * as SecureStore from 'expo-secure-store';

export const apiClient = axios.create({
  baseURL: process.env.EXPO_PUBLIC_API_BASE_URL,
  headers: { 'Content-Type': 'application/json' },
});

apiClient.interceptors.request.use(async (config) => {
  const token = await SecureStore.getItemAsync('auth_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

apiClient.interceptors.response.use(
  (res) => res,
  async (error) => {
    if (error.response?.status === 401) {
      // Token expired — trigger logout via store
      const { useAuthStore } = await import('../store/auth');
      useAuthStore.getState().logout();
    }
    return Promise.reject(error);
  }
);
```

**`src/store/auth.ts`**
- Zustand store with `user`, `token`, `isAuthenticated`
- `login(token, user)` → `SecureStore.setItemAsync('auth_token', token)`
- `logout()` → `SecureStore.deleteItemAsync('auth_token')` + clear user
- `initialize()` → check SecureStore on app launch, rehydrate if token exists

**`app/_layout.tsx`**
- Wrap tree with `<QueryClientProvider>` and `<GestureHandlerRootView>`
- Call `auth.initialize()` on mount
- Show a loading screen while initializing
- Route guard: if not authenticated, redirect to `/(auth)/login`

**`app/(auth)/login.tsx`**
- Full login UI — this is P0, wire the real API call here
- Handle OAuth flow with `expo-auth-session` if applicable
- Call `auth.login(token, user)` on success → navigation happens via root layout

**`src/api/auth.ts`**
- Implement all auth API functions (login, logout, OAuth token exchange, etc.)
- These get called from `app/(auth)/login.tsx`

### 3E. All Other Screens — Scaffold with Detailed TODOs

The goal is that a user who opens the mobile app immediately recognizes it as the mobile
version of their web app — same brand colors, same typographic feel, same component style.
Before writing any screen, look at the corresponding web page and mirror its layout and
visual hierarchy as closely as React Native allows.

For every screen beyond login, create the file with:
- Proper TypeScript component structure
- Full UI layout using NativeWind classes that matches the web page's look and feel:
  - Use the same primary/accent colors from `theme.ts` and `tailwind.config.js`
  - Replicate the web page's card style (shadows, border, radius) using the `shadows.card` from `theme.ts`
  - Match button shapes, fill styles, and variants (solid/outline/ghost) from the web
  - Use `typography` constants from `theme.ts` for all text — don't hardcode font sizes
  - Preserve the information hierarchy of the web page (what's prominent stays prominent)
  - Read the actual web component for the screen — don't invent a generic layout
- API call locations marked with TODO comments that contain everything needed to wire them:

```tsx
// TODO: Load order list
// Endpoint: GET /api/orders
// Auth: Required (axios interceptor handles it automatically)
// Query key: ['orders']
// API function: create in src/api/orders.ts as orders.list()
// Response type: { orders: Order[]; pagination: { page: number; total: number } }
// Success: render orders in FlatList below
// Loading: show ActivityIndicator
// Error: show retry button
//
// const { data, isLoading, error, refetch } = useQuery({
//   queryKey: ['orders'],
//   queryFn: () => orders.list(),
// });
```

The TODO comment should be so complete that wiring it up is mechanical, not investigative.

Also create stub files in `src/api/[feature].ts` for each domain — empty functions
with correct TypeScript signatures, so the import structure is already in place.

### 3F. Save BUILD_NOTES.md

```markdown
# Build Notes — [App Name]

## Setup
1. Copy `.env.example` to `.env.local` and fill in:
   - `EXPO_PUBLIC_API_BASE_URL` — your backend URL
   - [any OAuth vars]
2. Run: `npx expo start`

## What's Fully Wired
- [x] Auth store (Zustand + SecureStore)
- [x] Axios client (auth interceptor, 401 handling)
- [x] Login screen
- [x] Root layout (auth gate, QueryClientProvider)

## TODOs (API Wiring)
- [ ] [screen name] — [endpoint] — [file:line]
- [ ] [screen name] — [endpoint] — [file:line]
...

## OAuth Setup Required
[If OAuth] Register these redirect URIs with your OAuth provider:
- `[scheme]://` (e.g. `myapp://`)

## Backend: CORS
Ensure your backend allows requests from Expo dev client:
- Origin: `http://localhost:8081` (dev)
- Add your production domain when deploying
```

Present the summary:

> "The project is scaffolded at `[path]`. Auth is fully wired end-to-end. Every other
> screen has the full UI with detailed TODO markers showing exactly what to implement.
> Check `BUILD_NOTES.md` for the complete list. When you're ready, say **GO** and I'll
> wire up all the API calls."

**Stop here. Wait for explicit GO.**

---

## Phase 4: Wire Up All API Calls

Work domain by domain (not screen by screen) — complete the entire API layer for one
feature before moving to the next. This keeps `src/api/` coherent.

For each TODO:
1. Implement the API function in `src/api/[feature].ts`
2. Replace the TODO comment with the real `useQuery` / `useMutation` call
3. Implement loading state (skeleton or ActivityIndicator)
4. Implement error state (user-visible message + retry option)
5. Add TypeScript types for request/response

Common patterns to use consistently:

```ts
// Read operation
const { data, isLoading, error, refetch } = useQuery({
  queryKey: ['feature', id],
  queryFn: () => featureApi.get(id),
});

// Write operation
const mutation = useMutation({
  mutationFn: (data: CreateFeatureInput) => featureApi.create(data),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['feature'] });
    router.back();
  },
});
```

When all TODOs are done, update `BUILD_NOTES.md` to reflect completion and note
anything that still needs manual setup (OAuth URIs, backend CORS, push notification
certificates, App Store/Play Store submission steps).

---

## Key Principles

**Read before writing** — every API endpoint and page you document should come from
actually reading the code, not guessing from filenames.

**Auth is P0** — the whole app is blocked if auth doesn't work. Wire it fully in Phase 3,
don't leave it as a TODO.

**Don't rebuild the backend** — if the API exists, use it. Don't suggest rewriting
endpoints or changing the backend auth model to suit mobile.

**Secure token storage** — always `expo-secure-store`, never `AsyncStorage` for
anything sensitive. AsyncStorage is unencrypted.

**The TODO comments are a contract** — the owner may choose to wire them up themselves.
Write TODOs detailed enough that a junior developer could follow them without reading
the web codebase.

**One framework, consistently** — TanStack Query for all server state, Zustand for
all client state, NativeWind for all styling. Don't mix patterns across screens.

**The mobile app must look like the web app** — users who know the web product should
instantly recognize the mobile version. Read the web UI before scaffolding each screen.
Use `theme.ts` for all visual tokens — colors, typography, radius, shadows. A screen
that is structurally correct but visually unrecognizable is not done.
