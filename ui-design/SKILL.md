---
name: ui-design
version: 1.0.3
description: |
  Web UI design skill. Designs production-ready React components and layouts using
  MagicUI as the primary component library, Shadcn/ui as base primitives, Tailwind
  for styling, and Phosphor icons. Asks for design preferences (style, palette, dark
  mode), optionally crawls reference URLs/Figma for inspiration, generates both an
  HTML preview (Tailwind CDN) and a React preview (real MagicUI/Phosphor/Shadcn) before
  writing production code, so you can compare the two and catch rendering differences early.
  Updates ui-design.md with confirmed design tokens and DESIGN.md when present.
  Use when asked to "design a component", "build a UI", "/ui-design", or "design this page".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - WebSearch
  - Agent
  - WebFetch
---

## Pre-flight — Version Check

Run this silently before anything else. Do NOT mention it to the user unless the skill is outdated.

**Step 1 — Fetch the latest version manifest:**

Use WebFetch to GET `https://raw.githubusercontent.com/TekLabsVN/Teklabs-claude-custom-skills/main/versions.json`

- If the fetch fails (network error, offline), skip this entire phase silently and continue to Phase 0.
- If it succeeds, parse the JSON and read `skills.ui-design` as `LATEST_VERSION`.

**Step 2 — Compare versions:**

The current installed version of this skill is defined in the frontmatter above: `version: 1.0.0` — call this `CURRENT_VERSION`.

Compare `CURRENT_VERSION` with `LATEST_VERSION` using semantic versioning. If they are equal, skip the rest of this phase silently.

**Step 3 — Prompt the user (only if outdated):**

If `LATEST_VERSION` is newer than `CURRENT_VERSION`, use AskUserQuestion to ask:

> "The **ui-design** skill you're using is **v{CURRENT_VERSION}**, but **v{LATEST_VERSION}** is available. Auto-update now? (yes / no — update will overwrite `~/.claude/skills/ui-design/SKILL.md`)"

**Step 4 — Auto-update (only if user says yes):**

1. Use WebFetch to GET `https://raw.githubusercontent.com/TekLabsVN/Teklabs-claude-custom-skills/main/ui-design/SKILL.md`
2. Use Write to overwrite `~/.claude/skills/ui-design/SKILL.md` with the fetched content.
3. Tell the user: "✓ ui-design skill updated to v{LATEST_VERSION}. Please re-run `/ui-design` to use the latest version." Then STOP — do not continue with the outdated skill logic.

If the user says no, continue with the current skill as-is.

---

## Phase 0 — Silent Context Gathering

Run these checks silently before asking the user anything.

### 0A. Read DESIGN.md

```bash
cat DESIGN.md 2>/dev/null || echo "NO_DESIGN_MD"
```

If found, extract and remember:
- Color palette (primary, secondary, accent, neutrals, background)
- Font families (display, body, UI)
- Design style / aesthetic direction
- Dark mode preference (light / dark / both)
- Spacing scale / base unit
- Any existing component registry

### 0B. Scan for existing components

```bash
find . -type f -name "*.tsx" -o -name "*.jsx" | grep -iE "(component|ui|shared)" | grep -v node_modules | grep -v ".next" | head -40
```

Note any existing components that might overlap with what the user is about to request. You'll surface relevant ones during intake.

### 0C. Check installed libraries

```bash
cat package.json 2>/dev/null | grep -E '"magicui|@phosphor-icons|shadcn|tailwindcss|framer-motion"'
```

Note which are present and which are missing. You'll mention missing ones before generating code.

---

## Phase 1 — Design Intake

Use AskUserQuestion to gather design preferences. Ask all at once (max 4 questions).

**Question 1 — What to design**
Ask: "What component, section, or page do you want to design? Describe it freely — what it does, who uses it, and any key interactions."

**Question 2 — Reference materials** (optional)
Ask: "Any reference URLs, Figma links, or screenshots for visual inspiration? (paste a URL or skip)"
- If a URL is provided: use WebSearch or the browse skill to crawl it and extract:
  - Dominant colors used
  - Layout patterns
  - Typography style
  - Mood / aesthetic direction
  - Component patterns you can borrow

**Question 3 — Design style**
Present these options (allow mix or custom):
- **Minimalism** — Less is more. Ample white space, simple typography, reduced palette. Clean and elegant.
- **Flat / Flat 2.0** — 2D elements, bright colors. Flat 2.0 adds subtle shadows for depth.
- **Glassmorphism** — Translucent frosted-glass panels, vivid backgrounds, layered depth.
- **Neumorphism** — Soft-UI. Elements seem to extrude from the background with inner shadows.
- **Maximalism** — More is more. Vibrant clashing colors, layered textures, dense composition.
- **Swiss / Grid** — Strong modular grid, clean sans-serif, disciplined whitespace.
- **Bento** — Tile-based, rounded rectangles, dashboard-grid layout.
- **Retrofuturism / Y2K** — Grainy textures, neon, nostalgia. 80s–90s inspired.
- **Hand-Drawn** — Sketchy lines, imperfect shapes, personal handmade feel.
- **Collage** — Photography + stickers + textures, scrapbook playfulness.
- Or describe a mix / something else.

If DESIGN.md specifies a style, pre-fill the question with that style and ask for confirmation or override.

**Question 4 — Dark / Light mode**
- Light only
- Dark only
- Both (generate both variants)

If DESIGN.md specifies, pre-fill and confirm.

### After intake: Color Palette

If no color palette was provided and DESIGN.md has none, **auto-recommend one** based on the chosen style + project name/purpose. Display it before proceeding:

```
Recommended palette:
  Primary:    #1A1A2E  (Deep navy)
  Secondary:  #16213E  (Slate blue)
  Accent:     #E94560  (Coral red)
  Neutral:    #F5F5F5  (Off-white)
  Background: #0F3460  (Dark indigo)
```

Ask: "Does this palette work, or would you like to adjust it?"

Once the palette is confirmed, write/update `ui-design.md` in the project root with the confirmed design tokens:

```markdown
# UI Design Tokens

## Style
[confirmed style name(s)]

## Color Palette
| Token      | Hex     | Description |
|------------|---------|-------------|
| Primary    | #...    | ...         |
| Secondary  | #...    | ...         |
| Accent     | #...    | ...         |
| Neutral    | #...    | ...         |
| Background | #...    | ...         |

## Typography
- Display: [font name or TBD]
- Body: [font name or TBD]
- UI: [font name or TBD]

## Dark Mode
[Light only / Dark only / Both]

## Components
<!-- Auto-populated by /ui-design -->
```

If `ui-design.md` already exists, update only the fields that changed (preserve the Components section).

---

## Phase 2 — Component Plan

No user interaction in this phase. Think through the design silently, then print a brief plan:

### Component architecture
- Name, file path, and subcomponents
- Props interface (TypeScript)
- States to implement: **default, hover, active, focus, loading, empty, error, disabled**
- Responsive strategy: mobile-first by default (sm → md → lg → xl breakpoints)

### Library mapping
- Which **MagicUI** components to use (e.g., `MagicCard`, `AnimatedGradient`, `ShimmerButton`, `BorderBeam`, `AnimatedBeam`, `NumberTicker`, `Meteors`, etc.)
- Which **Shadcn** primitives as base layer (e.g., `Button`, `Card`, `Dialog`, `Input`, `Badge`, etc.)
- Which **Phosphor** icons needed and their weight (Regular / Bold / Fill / Duotone / Thin / Light)
- Tailwind utility strategy (colors from palette, spacing scale, typography)

### Deduplication check
If a similar component was found in Phase 0B, surface it:
> "I found `components/ui/CardGrid.tsx` which handles a similar layout. Should I extend it, or design a new component from scratch?"

### Layout differentiation
Do NOT use cookie-cutter layouts. Actively vary:
- Composition axis (horizontal / vertical / diagonal / radial)
- Anchor point (center / off-center / edge-pinned)
- Grid structure (symmetric / asymmetric / intentionally broken)
- Density (generous whitespace vs. controlled density)

No two components should have the same skeleton.

---

## Phase 3 — HTML Preview

Generate a self-contained HTML preview that demonstrates the design visually. This is NOT a React file — it uses Tailwind CDN and vanilla JS for speed.

**Save path:** `design/previews/[component-name]-preview.html` (create the directory if it doesn't exist).
This keeps all previews versioned with the project rather than floating in a temp location.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>[Component Name] Preview</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script>
    tailwind.config = {
      theme: {
        extend: {
          colors: {
            // Insert palette from Phase 1
          }
        }
      },
      darkMode: 'class'
    }
  </script>
  <style>
    /* Any custom CSS for effects that Tailwind can't express cleanly */
  </style>
</head>
<body class="[bg-color] min-h-screen flex items-center justify-center p-8">
  <!-- Component HTML here -->
  <!-- Include all key states: hover states via CSS, show loading/empty/error variants stacked -->
</body>
</html>
```

Write the file to `design/previews/[component-name]-preview.html`, then open it:

```bash
mkdir -p design/previews && open design/previews/[component-name]-preview.html
```

Then ask the user: "Preview is open in your browser. Does the direction look right? Proceed as-is, or any adjustments before I write the React code?"

If the user wants adjustments: iterate on `preview.html` only (fast cycle). Repeat until approved.

---

## Phase 3B — React Preview Page

Once the HTML preview is approved, generate a React preview page using the actual production libraries. This lets the user compare the two outputs and catch any rendering differences before the component is integrated.

**Save path:** `design/previews/[component-name]-preview.tsx`

Rules for the React preview:
- A standalone Next.js page or React component that renders the design using real libraries
- Import and use actual **MagicUI** components (not simulated HTML equivalents)
- Import **Phosphor** icons: `import { IconName } from "@phosphor-icons/react"`
- Use **Shadcn/ui** primitives as structural base
- Use **Tailwind** classes with the confirmed palette tokens
- Wrap in a centered `<div>` with matching background so it previews cleanly at any route
- Include all key states visible on screen (stacked or tabbed) — same as the HTML preview
- Add a small `// PREVIEW ONLY` comment at the top so it's clear this is not production code

```tsx
// PREVIEW ONLY — delete before shipping
"use client";

import { MagicCard } from "@/components/magicui/magic-card";
import { ArrowRight } from "@phosphor-icons/react";
// ... other imports

export default function [ComponentName]Preview() {
  return (
    <div className="min-h-screen bg-[#...] flex items-center justify-center p-8">
      {/* Default state */}
      {/* Loading state */}
      {/* Error state */}
      {/* Empty state */}
    </div>
  );
}
```

Open both previews for comparison:

```bash
open design/previews/[component-name]-preview.html
open design/previews/[component-name]-preview.tsx
```

(The `.tsx` preview runs via the project's dev server at its file path — mention the route to the user.)

Then ask: "Both previews are ready. HTML preview (fast/approximate) and React preview (actual libraries). Do they look consistent? Any final adjustments before I write the production component?"

If differences exist between the two, note them explicitly:
> "The React preview uses MagicUI's actual border beam effect, which adds a subtle animated glow the HTML preview simulated with CSS. Everything else matches."

---

## Phase 4 — Production React Code

Write the production component(s). Follow these rules:

### File structure
```
components/[name]/
  index.tsx          ← main component
  [name].types.ts    ← TypeScript interfaces/types (if substantial)
```

Or a single file if simple: `components/ui/[Name].tsx`

### Code standards
- **TypeScript** — full type coverage, no `any`
- **MagicUI** as primary visual components
- **Shadcn** primitives as structural base
- **Phosphor** icons: `import { IconName } from "@phosphor-icons/react"`
- **Tailwind** for all layout/spacing/color — use CSS variables for palette
- **Dark mode**: all `bg-*`, `text-*`, `border-*` classes paired with `dark:` variants

### Accessibility — MANDATORY (never skip)
Every component must include:
- Semantic HTML elements (`<nav>`, `<main>`, `<article>`, `<section>`, `<button>`, etc.)
- ARIA roles where native semantics are insufficient
- `aria-label` / `aria-labelledby` on interactive elements
- Keyboard navigation: all interactive elements reachable via Tab, activated via Enter/Space
- Focus rings: `focus-visible:ring-2 focus-visible:ring-[accent]`
- Color contrast: WCAG 2.1 AA minimum (4.5:1 for normal text, 3:1 for large text)
- `alt` text on all images

### All states — MANDATORY (never skip)
```tsx
// Always implement:
// • Default
// • Hover (via Tailwind hover: prefix)
// • Active / pressed
// • Focus-visible
// • Loading (skeleton or spinner variant)
// • Empty (no data variant)
// • Error (error message variant)
// • Disabled (when applicable)
```

### Missing libraries
If any required library is not in package.json, output install commands at the top as a comment:
```
// Run first: npm install @phosphor-icons/react
// Run first: npx magicui-cli add magic-card
```

---

## Phase 5 — Design Doc Updates

### ui-design.md — Components registry (always)

Append the new component to the `## Components` section of `ui-design.md` (created in Phase 1):

```markdown
### [ComponentName]
- **File**: `components/[name]/index.tsx`
- **Preview**: `design/previews/[name]-preview.html`
- **Variants**: default, loading, empty, error
- **Color tokens**: primary, accent
- **Icons**: `ArrowRight`, `SpinnerGap` (Phosphor)
- **MagicUI**: `MagicCard`, `ShimmerButton`
```

### DESIGN.md — if present

If `DESIGN.md` also exists, append the same component entry to its `## Components` registry to keep both in sync.

---

## Design Anti-patterns — NEVER do these

- **Generic layouts**: centered card on white background with blue CTA button
- **Overused fonts**: Inter, Roboto, Arial, system-ui as body font (use something with character)
- **Same skeleton twice**: if this project already has a card component, don't build another with the same grid
- **AI slop colors**: purple gradient on white, teal-on-grey, generic blue primary
- **Inaccessible shortcuts**: skipping ARIA, not implementing focus states, poor contrast ratios
- **Placeholder states forgotten**: components that break or look empty when loading/no-data
- **Mobile afterthought**: designing desktop-first, then crunching to mobile

---

## Completion

When done, output:

```
✓ HTML Preview:   design/previews/[name]-preview.html
✓ React Preview:  design/previews/[name]-preview.tsx
✓ Design tokens:  ui-design.md (created / updated)
✓ Component:      components/[name]/index.tsx
✓ States:         default, hover, active, focus, loading, empty, error
✓ Accessibility:  WCAG 2.1 AA, ARIA roles, keyboard nav
✓ Dark mode:      [yes / no / both]
✓ DESIGN.md:      [updated / not found]

Missing installs (if any):
  npm install @phosphor-icons/react
  npx magicui-cli add [component]
```
