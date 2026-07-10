# Design system

## Surfaces

| Surface | Framework / tech | Entry point |
|---------|------------------|-------------|
| plugin | Claude Code Skills (`.claude-plugin/plugin.json` + `skills/*/SKILL.md`, no `commands/` or `agents/` dirs) | `/voice-harvest`, `/voice-doc`, `/voice-email`, `/voice-chat`, `/voice-rewrite`, `/voice-tune`, `/voice-card`, plus natural-language auto-trigger per skill's `description` frontmatter |

Single surface. No web UI, CLI binary, TUI, REST API, or report/export template exists anywhere in the repo — the product *is* eight Claude Skills; `voice-profile` is a data-only skill (never invoked directly, README.md:8) rather than a distinct surface. `voice-card` compiles a portable prompt block delivered in the chat response, not a rendered report/export template — it doesn't introduce a new surface either.

*(High confidence — confirmed by directory layout: `skills/` contains only `SKILL.md` + `references/`, no `src/`, no server, no `package.json`/entry-point script.)*

## Semantic palette

Not applicable to this surface. Claude Skills are markdown instructions consumed by the model, not rendered UI — there is no color/style state to map (no terminal styling library, no CSS, no ANSI codes anywhere in `skills/`).

## Vocabulary

The product's concepts are named consistently at the top level (skill names, register names) but the **AI-tells / anti-leakage vocabulary is duplicated across four independent lists** rather than sourced from one place — this is the vocabulary layer's main finding.

| Concept | Canonical display | Source of truth | Consumers |
|---------|-------------------|-----------------|-----------|
| Register names | `longform`, `email`, `chat` | `skills/voice-profile/references/_format.md` (defines the 3 register files) | voice-harvest (writes), voice-doc/voice-email/voice-chat (read their own register), voice-tune (patches) |
| Register file section headings | `## Traits`, `## Exemplars`, `## Anti-patterns`, `## Strunk exemptions` (longform only), `## Coverage` | `skills/voice-profile/references/_format.md:1-59` — "Keep the section headings stable — the generators key off them" | voice-harvest, voice-tune, all 4 generators |
| Confidence tier | `high` / `medium` / `low` | `_format.md:57`, restated ad hoc in each generator's fallback logic | voice-doc, voice-email, voice-chat, voice-rewrite |
| **AI-tells / anti-leakage list** | *(no canonical form — see below)* | **No single source.** Four independent, overlapping-but-non-identical lists | voice-profile (SKILL.md:85-95, "Anti-leakage checklist"), voice-doc (SKILL.md:105-107), voice-rewrite (SKILL.md:37-40), voice-harvest (SKILL.md:186-189, "stylometric discontinuity" signals) |

**The AI-tells drift, concretely:** all four independently list "delve/leverage/streamline" and "I hope this finds you well" / "I hope this helps," but only voice-profile and voice-doc mention "triads" ("clear, concise, and compelling"); only voice-harvest frames it as *exclusion signals during harvest* (echo match, stylometric discontinuity, structural tells) rather than a delivery-time checklist; only voice-rewrite frames "hedge-free over-confidence or its opposite" as a tell. This is exactly issue #7's finding #5 — tracked there as "AI-tells list scattered and stale," proposing consolidation into one `references/ai-tells.md`.

*(High confidence — read directly from all four files; line numbers cited above.)*

## Formatting

- **Sentence-length stats**: reported as "mean N words, range A–B" (e.g. `_format.md:14`, "mean 14 words, range 4–31"). Consistent format wherever traits are quantified.
- **Sample counts**: reported as a plain integer + unit (e.g. "240 messages," "sample count: how many authentic samples"). No consistent minimum-sample threshold exists yet — flagged in issue #6 as a gap, not a formatting inconsistency.
- **Date ranges**: `YYYY-MM` to `YYYY-MM` (e.g. `_format.md:86`, "2024-01 to 2025-12").
- **Confidence disclosure string**: no single canonical sentence — each generator writes its own "this leans on craft defaults" disclosure ad hoc (voice-doc:109-110 vs. voice-profile:82-83 vs. others) rather than sharing one template string.
- No numeric/currency formatting anywhere (not applicable — no financial or quantitative UI).

*(Medium confidence — formatting patterns for stats are consistent by convention, not enforced by any shared template; the disclosure string is confirmed inconsistent by direct comparison.)*

## Per-surface conventions

### Plugin / prompt tooling

- **Skill naming**: `voice-<verb-or-noun>` — `voice-harvest`, `voice-profile`, `voice-doc`, `voice-email`, `voice-chat`, `voice-rewrite`, `voice-tune`, `voice-card`. Flat, no prefix families (contrast with Studious's own `gate-`/`deep-review` prefixing) — each skill name stands alone as the invocation command.
- **Frontmatter convention**: every `SKILL.md` has exactly `name` + `description` (YAML block, `description` as a folded `>` block). No `allowed-tools`, no other frontmatter fields, in any of the 8 skills — a flatter contract than plugins that restrict tool access per skill.
- **Trigger convention**: descriptions embed explicit quoted trigger phrases ("draft a Slack message," "make this sound like me") plus explicit hand-off phrases to sibling skills ("for email use voice-email"). Every generator's description ends with a disambiguation clause pointing at the other 3 generators — a deliberate, repeated pattern (confirmed in all 4 generator frontmatters), not incidental duplication. `voice-card` follows the same disambiguation convention, pointing at the generators and voice-harvest instead of at other generators.
- **No verdict/output vocabulary**: unlike a gate-style plugin, no skill emits a canonical result token (no `PASS`/`FAIL`, no `BUILD`/`DEFER`). Output is always a prose draft, a written/patched profile file, or (for `voice-card`) a compiled static block — the "result" is the artifact itself.
- **No severity/tier vocabulary in reports**: the only tiered vocabulary in the product is the profile's `high`/`medium`/`low` confidence tier (see Vocabulary, above) — there is no Critical/Important/Minor-style finding severity because the product doesn't produce audit-style reports.
- **Report/output structure**: register files (`longform.md`/`email.md`/`chat.md`) follow the fixed section order in `_format.md` (Traits → Exemplars → Anti-patterns → [Strunk exemptions] → Coverage). This is the one place a strict structural contract is enforced by convention across every register file.

*(High confidence — directly observed across all 8 `SKILL.md` files and the format contract.)*

## Anti-patterns (do NOT do these)

<!-- FILL IN based on intent: is a 5th AI-tells list (e.g. adding one to a future skill) an anti-pattern to flag here, pending issue #7's consolidation? Is hardcoding a claude.ai-only path (issue #5) an anti-pattern worth naming explicitly so it doesn't recur in a future skill? -->
