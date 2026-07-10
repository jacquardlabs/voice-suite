## Review workflow

### Context documents

- **PRODUCT.md** — product context, personas, principles, feature map. Read before any product decision.
- **DESIGN.md** — the interface design system: the product's user-facing surface(s) — web UI, CLI, TUI, API, or report — covering the semantic palette, vocabulary, formatting, and per-surface conventions. Read before changing anything users see. (CLAUDE.md owns *how the code is written*; DESIGN.md owns *the user-facing surface*.)

### Code conventions

This repo has no application source — it is 7 Claude Skills (`skills/*/SKILL.md` + `references/`), a plugin manifest, and release tooling. There is no language to lint (`pyproject.toml` only configures `python-semantic-release`; no Python/JS/TS source exists).

- **Skills/prompts** — Markdown SKILL.md files with `name` + `description` YAML frontmatter only (no `allowed-tools` or other fields, by convention — see DESIGN.md). When editing anything under `skills/`, use the `writing-skills` meta-skill first.
- **Linter** — none; there is no source to lint. `/gate-audit`'s code-quality and docs checks apply to prompt clarity and cross-skill consistency instead of language idiom.
- **Deliberate deviations** — none recorded yet.

### Quality gates

| Gate | When | Command |
|------|------|---------|
| Should we build? | Before any engineering | `/gate-should-we-build [idea]` |
| Design review | After design doc, before implementation | `/gate-design-review` |
| Audit | After implementation, before acceptance | `/gate-audit` |
| Acceptance | After audit passes, before merge | `/gate-acceptance` |

### Periodic reviews

| Review | Cadence | Command |
|--------|---------|---------|
| Codebase health | Weekly or pre-milestone | `/deep-review codebase` |
| Interface health | Monthly or post-UI-sprint | `/deep-review interface` |
| Architecture | Quarterly or pre-major-feature | `/deep-review architecture` |
| Product health | Monthly | `/deep-review product` |
| README drift | After a release or feature batch | `/deep-review readme` |
| All reviews + summary | As needed | `/deep-review` |

### After each review

1. Fix any **Critical** findings before the next feature
2. File **Important** findings as tasks to address this cycle
3. Log **Track** findings (lowest tier — revisit next cycle); they compound if ignored
4. Update context docs if the review surfaced changes:
   - `/deep-review product` updates PRODUCT.md
   - `/deep-review interface` updates DESIGN.md
   - `/deep-review architecture` updates CLAUDE.md
   - `/deep-review readme` proposes a README.md diff
