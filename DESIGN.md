# Design system

## Surfaces

| Surface | Framework / tech | Entry point |
|---------|------------------|-------------|
| plugin | Claude Code Skills (`.claude-plugin/plugin.json` + `skills/*/SKILL.md`, no `commands/` or `agents/` dirs) | `/voice-harvest`, `/voice-doc`, `/voice-email`, `/voice-chat`, `/voice-rewrite`, `/voice-tune`, `/voice-card`, `/voice-check`, plus natural-language auto-trigger per skill's `description` frontmatter |

Single surface. No web UI, CLI binary, TUI, REST API, or report/export template exists anywhere in the repo — the product *is* nine Claude Skills; `voice-profile` is a data-only skill (never invoked directly, README.md:8) rather than a distinct surface. `voice-card` compiles a portable prompt block delivered in the chat response, not a rendered report/export template — it doesn't introduce a new surface either. `voice-check` likewise delivers its deviation report inline in the chat response, not a rendered report template.

*(High confidence — confirmed by directory layout: `skills/` contains only `SKILL.md` + `references/`, no `src/`, no server, no `package.json`/entry-point script.)*

## Semantic palette

Not applicable to this surface. Claude Skills are markdown instructions consumed by the model, not rendered UI — there is no color/style state to map (no terminal styling library, no CSS, no ANSI codes anywhere in `skills/`).

## Vocabulary

The product's concepts are named consistently at the top level (skill names, register names), and the **AI-tells / anti-leakage vocabulary** — previously duplicated across four independent, drifting lists — now sources from one canonical file (see below).

| Concept | Canonical display | Source of truth | Consumers |
|---------|-------------------|-----------------|-----------|
| Register names | `longform`, `email`, `chat` | `skills/voice-profile/references/_format.md` (defines the 3 register files) | voice-harvest (writes), voice-doc/voice-email/voice-chat (read their own register), voice-tune (patches) |
| Register file section headings | `## Traits`, `## Exemplars`, `## Anti-patterns`, `## Strunk exemptions` (longform only), `## Coverage` | `skills/voice-profile/references/_format.md:1-59` — "Keep the section headings stable — the generators key off them" | voice-harvest, voice-tune, all 4 generators |
| Confidence tier | `high` / `medium` / `low` | `_format.md:57`, restated ad hoc in each generator's fallback logic | voice-doc, voice-email, voice-chat, voice-rewrite |
| **AI-tells / anti-leakage list** | Vocabulary / Structure / Register categories | `skills/voice-profile/references/ai-tells.md` — the one canonical file, added by issue #7's consolidation (`routing-tells-consolidation`) | voice-profile (fidelity procedure step 5, Anti-leakage checklist), voice-rewrite (Diagnose step), voice-harvest (Pass 2 exclusion signals), voice-check (generic-leakage half of its deviation report) — voice-doc already pointed at voice-profile's fidelity procedure before this consolidation (a side effect of `fidelity-consistency`'s dedup) and restates no vocabulary of its own |

**Resolved by the `routing-tells-consolidation` story (issue #7):** the four independent, overlapping-but-not-identical lists that used to live in voice-profile, voice-doc, voice-rewrite, and voice-harvest (three restated in full; voice-doc already a bare pointer) now converge on `skills/voice-profile/references/ai-tells.md` as the one full-text detector — every consumer names it by reference instead of restating it. voice-harvest still frames its own read of that file as *exclusion signals during harvest* (echo match, stylometric discontinuity, structural tells) rather than a delivery-time checklist; that's a legitimate difference in framing, not drift, since the underlying vocabulary is now the same file either way. The one deliberate exception is voice-harvest's embedded relay prompt (`skills/voice-harvest/references/relay-prompt.md`): it runs on a Claude surface with no file access to this skill's `references/`, so it carries its own necessarily self-contained copy of the vocabulary examples.

*(High confidence — read directly from the consolidated file and its pointer-consumers.)*

## Formatting

- **Sentence-length stats**: reported as "mean N words, range A–B" (e.g. `_format.md:14`, "mean 14 words, range 4–31"). Consistent format wherever traits are quantified.
- **Sample counts**: reported as a plain integer + unit (e.g. "240 messages," "sample count: how many authentic samples"). No consistent minimum-sample threshold exists yet — flagged in issue #6 as a gap, not a formatting inconsistency.
- **Date ranges**: `YYYY-MM` to `YYYY-MM` (e.g. `_format.md:86`, "2024-01 to 2025-12").
- **Confidence disclosure string**: no single canonical sentence — each generator writes its own "this leans on craft defaults" disclosure ad hoc (voice-doc:109-110 vs. voice-profile:82-83 vs. others) rather than sharing one template string.
- No numeric/currency formatting anywhere (not applicable — no financial or quantitative UI).

*(Medium confidence — formatting patterns for stats are consistent by convention, not enforced by any shared template; the disclosure string is confirmed inconsistent by direct comparison.)*

## Per-surface conventions

### Plugin / prompt tooling

- **Skill naming**: `voice-<verb-or-noun>` — `voice-harvest`, `voice-profile`, `voice-doc`, `voice-email`, `voice-chat`, `voice-rewrite`, `voice-tune`, `voice-card`, `voice-check`. Flat, no prefix families (contrast with Studious's own `gate-`/`deep-review` prefixing) — each skill name stands alone as the invocation command.
- **Frontmatter convention**: every `SKILL.md` has exactly `name` + `description` (YAML block, `description` as a folded `>` block). No `allowed-tools`, no other frontmatter fields, in any of the 9 skills — a flatter contract than plugins that restrict tool access per skill.
- **Trigger convention**: descriptions embed explicit quoted trigger phrases ("draft a Slack message," "make this sound like me") plus explicit hand-off phrases to sibling skills ("for email use voice-email"). Every generator's description ends with a disambiguation clause pointing at the other 3 generators — a deliberate, repeated pattern (confirmed in all 4 generator frontmatters), not incidental duplication. `voice-card` follows the same disambiguation convention, pointing at the generators and voice-harvest instead of at other generators. `voice-check` draws its own disambiguation line on grammatical mood: it owns the question form ("does this sound like me," "check this against my voice"), while voice-rewrite owns the imperative ("make this sound like me," "rewrite this in my voice") — a question gets a report, an imperative gets an edit.
- **No verdict/output vocabulary**: unlike a gate-style plugin, no skill emits a canonical result token (no `PASS`/`FAIL`, no `BUILD`/`DEFER`). Output is always a prose draft, a written/patched profile file, a compiled static block (`voice-card`), or a per-trait deviation report (`voice-check`) — the "result" is the artifact itself.
- **No severity/tier vocabulary in reports**: the only tiered vocabulary in the product is the profile's `high`/`medium`/`low` confidence tier (see Vocabulary, above) — there is no Critical/Important/Minor-style finding severity because the product doesn't produce audit-style reports. `voice-check`'s deviation report follows this too: per-trait findings only, no aggregate score and no severity-ranked findings list.
- **Report/output structure**: register files (`longform.md`/`email.md`/`chat.md`) follow the fixed section order in `_format.md` (Traits → Exemplars → Anti-patterns → [Strunk exemptions] → Coverage). This is the one place a strict structural contract is enforced by convention across every register file.

*(High confidence — directly observed across all 9 `SKILL.md` files and the format contract.)*

## Anti-patterns (do NOT do these)

- **Don't restate the AI-tells vocabulary in a new list.** Any skill that
  needs to check for assistant-register leakage points at
  `skills/voice-profile/references/ai-tells.md` — the one canonical
  Vocabulary/Structure/Register detector (see Vocabulary, above) — rather
  than hand-rolling its own copy. A 5th list anywhere in the repo would be
  the exact failure this file already documents happening once (four
  independent lists, drifted), not a new one.

<!-- FILL IN: is hardcoding a claude.ai-only path (issue #5) an anti-pattern worth naming explicitly too? Out of this story's scope — issue #5's path-resolution dedup landed via profile-durability/fidelity-consistency and is enforced by scripts/check-canonical-resolution-string.sh, but that enforcement is implicit (a guard script) rather than a stated anti-pattern here. Left for a future review to decide whether it's worth calling out explicitly in this section too. -->
