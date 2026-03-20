---
name: animate
version: 1.0.0
description: |
  Web animation skill. Orchestrates GSAP-powered animations across components, pages,
  or an entire site. Uses the full GSAP Club suite (ScrollTrigger, SplitText,
  ScrollSmoother, DrawSVG, etc.) for commercial projects. Pairs with Lenis for smooth
  scroll. Always enforces prefers-reduced-motion and transform/opacity-only rules.
  Produces an animation map before writing any code. Use when asked to "animate this",
  "add animations", "/animate", "add scroll effects", or "orchestrate the motion".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

## Phase 0 — Silent Context Gathering

Run silently before asking anything.

### 0A. Check DESIGN.md for motion preferences

```bash
cat DESIGN.md 2>/dev/null | grep -A 20 -i "motion\|animation\|transition\|scroll" || echo "NO_MOTION_SPEC"
```

If motion preferences are found, honor them as defaults for intensity and style.

### 0B. Check installed animation packages

```bash
cat package.json 2>/dev/null | grep -E '"gsap|lenis|@gsap|framer-motion"'
```

Note what's present. GSAP Club plugins (`@gsap/ScrollSmoother`, `@gsap/SplitText`, etc.) may be local — check:

```bash
ls node_modules/gsap/dist/ 2>/dev/null | grep -i "scrollsmoother\|splittext\|drawsvg\|motionpath" | head -10
```

### 0C. Find existing animation code

```bash
grep -r "gsap\|useGSAP\|ScrollTrigger\|lenis\|useAnimation\|motion\." --include="*.tsx" --include="*.ts" --include="*.js" -l 2>/dev/null | grep -v node_modules | grep -v ".next" | head -20
```

If existing animation code is found, read the relevant files to understand current patterns before proposing new ones. Match existing architecture where possible.

---

## Phase 1 — Animation Intake

Use AskUserQuestion to gather scope and preferences. Ask all at once (max 4 questions).

**Question 1 — Scope**
- Single component (one element or section)
- Single page (full page choreography)
- Full site (every page and shared elements: nav, footer, page transitions)

**Question 2 — Intensity**
- **Subtle** — Motion enhances, never distracts. Micro-interactions, soft fades, gentle reveals. User barely notices but misses it when gone.
- **Moderate** — Clear motion hierarchy. Staggered reveals, scroll-triggered entrances, purposeful transitions. Confident but not loud.
- **Expressive** — Big, choreographed sequences. Hero text character animations, parallax layers, dramatic scroll storytelling. Motion is a primary design element.

**Question 3 — Trigger types** (multi-select)
- On-load sequences (things that animate when the page first appears)
- Scroll-triggered (elements animate as they enter the viewport)
- Hover + interaction (micro-animations on hover, click, focus)
- Page transitions (route change animations)

**Question 4 — Lenis smooth scroll**
If scroll-triggered was selected in Q3:
- "Do you want Lenis smooth scroll? It pairs with GSAP ScrollTrigger for buttery scroll on macOS trackpads and smooth scroll across all devices."
- Recommend: Yes for full-site scope, optional for single-page.

---

## Phase 2 — Animation Map

Before writing any code, produce a choreography map. This is mandatory.

Format:
```
ANIMATION MAP — [project/page name]
═══════════════════════════════════════════════════════════════════════
TRIGGER          ELEMENT              ANIMATION                TIMING
───────────────────────────────────────────────────────────────────────
load             #nav                 fade-in + slide-down     0ms
load             .hero-eyebrow        fade-up                  100ms
load             .hero-title          SplitText char reveal    200ms  → 400ms
load             .hero-subtitle       fade-up                  500ms
load             .hero-cta            scale-in + glow pulse    600ms
scroll (20%)     .features-grid       stagger fade-up          80ms/card
scroll (40%)     .stat-number-1       count-up 0→847           on enter
scroll (40%)     .stat-number-2       count-up 0→12k           on enter, 200ms delay
scroll (60%)     .testimonial-cards   parallax drift -30px     continuous
scroll (80%)     .cta-section         fade-in + scale          on enter
hover            .nav-link            underline slide           150ms ease
hover            .card                lift + shadow deepen      200ms
hover            .cta-button          shimmer sweep             300ms
click            .mobile-menu         slide-down               250ms spring
═══════════════════════════════════════════════════════════════════════
PLUGINS NEEDED: ScrollTrigger, SplitText, Observer
LENIS: yes
```

Print the full map, then ask: "Does this choreography look right? Proceed as-is, or adjust any entries?"

Wait for approval before writing any code. If the user wants changes, update the map and re-show it.

---

## Phase 3 — Implementation

### 3A. Install missing packages

If GSAP or Lenis are missing:
```bash
npm install gsap lenis
```

For React projects, also:
```bash
npm install @gsap/react
```

Note: GSAP Club plugins (SplitText, ScrollSmoother, DrawSVG, MotionPathPlugin) are included in `gsap` when a Club license is present. Import them from `"gsap/SplitText"`, `"gsap/ScrollSmoother"`, etc.

### 3B. Architecture

Organize animations into three distinct layers:

**Layer 1: Load sequences** — runs once on page/component mount
```typescript
// Use a single master GSAP timeline for all load animations
// This makes timing globally adjustable (tl.timeScale(0.8) speeds/slows everything)
const tl = gsap.timeline({ defaults: { ease: "power2.out" } })

tl.from("#nav", { y: -60, opacity: 0, duration: 0.6 })
  .from(".hero-title .char", { y: 80, opacity: 0, stagger: 0.03, duration: 0.7 }, "-=0.3")
  .from(".hero-subtitle", { y: 30, opacity: 0, duration: 0.5 }, "-=0.4")
  .from(".hero-cta", { scale: 0.9, opacity: 0, duration: 0.4 }, "-=0.3")
```

**Layer 2: Scroll sequences** — ScrollTrigger driven
```typescript
// Each scroll animation is its own ScrollTrigger
// Group by section for clarity
gsap.utils.toArray(".feature-card").forEach((card, i) => {
  gsap.from(card, {
    scrollTrigger: {
      trigger: card,
      start: "top 85%",
      toggleActions: "play none none none",
    },
    y: 50,
    opacity: 0,
    duration: 0.6,
    delay: i * 0.08,
    ease: "power2.out",
  })
})
```

**Layer 3: Interaction micro-animations** — event-driven
```typescript
// Keep these lightweight — CSS transitions handle most hover states
// Reserve GSAP for sequences that CSS can't do (shimmer sweeps, multi-step hovers)
```

### 3C. Non-negotiable rules (enforce on every animation)

**1. prefers-reduced-motion — ALWAYS wrap**

```typescript
// At the top of every animation file/hook:
const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches

if (prefersReducedMotion) {
  // Skip animations entirely — elements should be in their final visible state
  gsap.set(".animated-element", { opacity: 1, y: 0, scale: 1 })
  return
}

// Normal animations below
```

For React with `useGSAP`:
```typescript
import { useGSAP } from "@gsap/react"
import { useReducedMotion } from "./hooks/useReducedMotion"

const prefersReducedMotion = useReducedMotion()

useGSAP(() => {
  if (prefersReducedMotion) {
    gsap.set(scope.current, { opacity: 1 })
    return
  }
  // animations...
}, { scope: containerRef })
```

**2. Transform + opacity ONLY**

```typescript
// ✓ GOOD — GPU-composited, no layout reflow
gsap.from(el, { x: 0, y: 50, opacity: 0, scale: 0.95, rotation: 5 })

// ✗ BAD — triggers layout reflow, causes jank
gsap.from(el, { width: "0px", height: "0px", top: "100px", left: "50px", marginTop: "20px" })
```

**3. will-change on animated elements** (set via CSS, not GSAP)
```css
.animated-card {
  will-change: transform, opacity;
}
```
Remove after animation completes for elements that don't loop:
```typescript
tl.eventCallback("onComplete", () => {
  gsap.set(".hero-title", { willChange: "auto" })
})
```

**4. ScrollTrigger cleanup on unmount (React)**
```typescript
useGSAP(() => {
  const triggers: ScrollTrigger[] = []
  // ... create triggers and push to array
  return () => triggers.forEach(t => t.kill())
}, { scope: containerRef })
```

### 3D. Lenis setup (if enabled)

```typescript
// app/layout.tsx or _app.tsx
import Lenis from "lenis"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"

gsap.registerPlugin(ScrollTrigger)

const lenis = new Lenis()

lenis.on("scroll", ScrollTrigger.update)

gsap.ticker.add((time) => {
  lenis.raf(time * 1000)
})

gsap.ticker.lagSmoothing(0)
```

### 3E. SplitText for hero/display text

When animating hero headlines or large display text, always use SplitText:
```typescript
import { SplitText } from "gsap/SplitText"
gsap.registerPlugin(SplitText)

const split = new SplitText(".hero-title", { type: "chars,words" })

tl.from(split.chars, {
  y: 100,
  opacity: 0,
  rotationX: -90,
  transformOrigin: "0% 50% -50",
  stagger: 0.02,
  duration: 0.7,
  ease: "back.out(1.7)",
})

// Revert SplitText on cleanup to restore original DOM
// split.revert() — call on unmount
```

---

## Phase 4 — Verify

After implementing, verify the animations work:

1. Use the `/browse` skill to open the page and observe:
   - Load sequence fires correctly
   - Scroll triggers activate at the right scroll positions
   - Hover states are smooth and not jittery
   - No console errors (especially `GSAP target not found` warnings)

2. Check for overwhelming motion:
   - If more than 5 elements animate simultaneously on load → suggest staggering them
   - If scroll animations feel "busy" → suggest reducing trigger count or spacing them further apart
   - If user asked for "subtle" but the map has SplitText + parallax + count-up → flag the intensity mismatch

3. If issues found, iterate on the animation code directly. Do not rework the UI components.

---

## Animation Anti-patterns — NEVER do these

- **No prefers-reduced-motion check**: Legal accessibility violation. Non-negotiable.
- **Layout-triggering properties**: `width`, `height`, `top`, `left`, `margin`, `padding` in GSAP. Always use transforms.
- **Animating everything**: If more than 60% of page elements have scroll triggers, it will feel overwhelming. Less is more.
- **Competing with UI**: Don't adjust colors, fonts, or layouts inside the animate skill. That's `/ui-design`'s domain.
- **No cleanup on unmount**: ScrollTriggers that aren't killed cause memory leaks and duplicate animations on re-mount.
- **Ignoring existing patterns**: If the codebase already uses Framer Motion for micro-animations, don't introduce GSAP for the same things. Add GSAP only for what Framer can't do (complex scroll sequences, SplitText, etc.).
- **Fighting with Lenis**: If Lenis is enabled, do NOT also use GSAP ScrollSmoother. They conflict. Pick one.

---

## Completion

When done, output:

```
✓ Animation map:     [X] elements choreographed
✓ Load sequences:    [X] animations in master timeline
✓ Scroll triggers:   [X] ScrollTrigger instances
✓ Interactions:      [X] hover/click animations
✓ Lenis:             [enabled / disabled]
✓ Plugins used:      ScrollTrigger, SplitText, [others]
✓ Reduced motion:    enforced (elements visible when motion disabled)
✓ Performance:       transform/opacity only, will-change set, cleanup on unmount

GSAP install (if needed):
  npm install gsap lenis
  npm install @gsap/react
```
