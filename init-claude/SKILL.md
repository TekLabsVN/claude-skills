---

description: "Initialize or refresh a repository CLAUDE.md. Use when setting up Claude Code for a new repository, when CLAUDE.md is missing"

model: sonnet

argument-hint: "[optional: --skip-confirm]"

allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion

---



Creates or migrates a repository CLAUDE.md. **Target**: under 80 lines, only repo-specific context.


## Step 1: Gather Architecture Constraints



**Do not skip** — this produces the highest-value content.



1. **Search** — use `Grep` for: base class patterns (`ServiceBase`, `BaseController`), multi-tenancy (`organisation_id`, `tenantId`), result/outcome types (`Result<>`, `.success?`), auth middleware, feature flag libraries (Flipper, LaunchDarkly, etc.), key base files. Show actual command output.



2. **Ask** — `AskUserQuestion` with 3–5 questions based on evidence found. Map signals to questions: base class→return value rules, org_id prevalence→scoping requirements, result types→convention scope, auth→policy approach, feature flags→naming/test patterns. Always ask: **"Known gotchas, legacy workarounds, or decisions that look wrong but have a specific reason?"**



3. **Place** — global constraints (multi-tenancy, auth, errors) → `CLAUDE.md`. File-specific patterns → `.claude/rules/` with `globs:` frontmatter. Total ≤15 lines → all in `CLAUDE.md`; >15 lines → split core/detail.



## Step 2: Generate or Migrate

### No Existing CLAUDE.md → Generate Fresh

Read `references/template.md`. Auto-fill: Purpose (repo name + README first line), Stack, Commands, Architecture Constraints (Step 2 findings), Key Files. Leave `<!-- TODO: fill in -->` for unconfirmed items.

**Write location**: always root `CLAUDE.md`. If both root and `.claude/CLAUDE.md` exist, prefer root.

**Unless `--skip-confirm`**, present analysis first:

```
Found: [N]-line CLAUDE.md
Discovered: [new constraints]
Keeping:   [sections]
Removing:  [sections — reason]
Result:    ~[N]-line CLAUDE.md [+ rules files]

Proceed? (yes / no / show diff)
```

Write only after `yes`. Write back to the detected path.

## Step 3: Present Result

Show the full CLAUDE.md content for review, plus summary:

```
✅ CLAUDE.md written (~N lines)
   ⚠️ Exceeds 80-line target  [only if N > 80]
📂 Rules files: [list, or "none"]
👉 Next: fill in Known Quirks, then commit
```

## Reference Files

- `references/template.md` — CLAUDE.md template with placeholders