## Review workflow

### Context documents

- **PRODUCT.md** — product context, personas, principles, feature map. Read before any product decision.
- **DESIGN.md** — the interface design system: the product's user-facing surface(s) — web UI, CLI, TUI, API, or report — covering the semantic palette, vocabulary, formatting, and per-surface conventions. Read before changing anything users see. (CLAUDE.md owns *how the code is written*; DESIGN.md owns *the user-facing surface*.)

### Code conventions

This repo has no application source — it is 8 Claude Skills (`skills/*/SKILL.md` + `references/`), a plugin manifest, and release tooling. There is no language to lint (`pyproject.toml` only configures `python-semantic-release`; no Python/JS/TS source exists).

- **Skills/prompts** — Markdown SKILL.md files with `name` + `description` YAML frontmatter only (no `allowed-tools` or other fields, by convention — see DESIGN.md). When editing anything under `skills/`, use the `writing-skills` meta-skill first.
- **Linter** — none; there is no source to lint. `/gauntlet:review`'s code-quality and docs checks apply to prompt clarity and cross-skill consistency instead of language idiom.
- **Deliberate deviations** — none recorded yet.

### Issue → PR

1. Implement the issue on a new branch, run the tests, and commit.
2. Run `/gauntlet:review`.
3. Fix the findings you judge real; list the ones you declined, with why.
4. Run `/exorcist:exorcise <issue>`.
5. Push and open the PR.

Design docs: `/viva-write design-doc`, then `/gauntlet:review <doc> --premortem`. Human sign-off on a doc or PR: `/viva-review`.

### Periodic reviews

Weekly or pre-milestone: `/gauntlet:review posture` and `/exorcist:seance`.

### After each review

1. Fix any **Critical** findings before the next feature
2. File **Important** findings as tasks to address this cycle
3. Log **Track** findings (lowest tier — revisit next cycle); they compound if ignored
