# Product context

## Why this product exists

Voice Suite is eight Claude Skills that mine text a user actually wrote, distill it into a structured voice profile, and generate new prose — docs, emails, chat messages, rewrites — in that same voice (README.md:1-3). The problem it targets: AI-drafted writing defaults to a generic, detectably-AI register (README.md:168, "not well-edited text, not generically-human text"); this product's bet is that a user's own writing, mined and quantified, is a better ground truth than any generic style guide. The design rules make this explicit: "Profile over everything… If a profile trait makes prose 'worse' by Strunk's lights, the trait wins" (README.md:168).

*(High confidence — stated directly in README.md.)*

## Who uses it

### Primary persona

A Claude user (Claude Code CLI/Desktop/IDE, or claude.ai web/Desktop) who writes routinely across registers — long-form docs, email, and chat/Slack — and wants AI-assisted drafts that read as theirs, not as Claude's. Evidenced by:
- The generator skills' own trigger phrases target routine work products: "write a doc," "reply to this," "draft a Slack message," "make this sound like me" (skills/voice-doc, voice-email, voice-chat, voice-rewrite frontmatter).
- The harvest sources it prioritizes — Claude chat history, Gmail, Slack, Notion (README.md:82-91) — are workplace/knowledge-worker tools, not consumer or creative-writing surfaces.
- Proposal #8 (git commit/PR history as a harvest source) frames "Claude Code users" as writing commits/PRs daily as their highest-frequency register — suggesting developers are a recognized sub-segment of the primary persona, not a separate one.

Frustration this addresses: AI drafts get edited into a "human" voice manually, every time, because the AI doesn't know the user's actual patterns — capitalization habits, sentence rhythm, sign-offs, words they'd never use. Success looks like: a first draft that needs little or no voice-editing, only content edits.

*(Medium confidence — inferred from skill trigger design and harvest source choices; no explicit persona doc exists yet.)*

### Secondary persona (if applicable)

<!-- FILL IN: Is there a distinct secondary persona (e.g., teams sharing one org voice, or a claude.ai-only user with no MCP/connector access who gets a degraded workflow)? The suite already treats claude.ai-web and Claude Code as different capability tiers (README.md's per-surface source-availability table) — is that a persona split worth naming, or just a platform-capability note? -->

## Product principles

- **Profile over everything** — the deliverable is the user's voice, not well-edited or generically-human text; an observed trait beats a style-guide rule even when the style guide would call it worse prose (README.md:168).
- **Voice wins, craft fills silence** — long-form generation layers two things in strict precedence: harvested voice (traits, exemplars, anti-patterns, Strunk-exemptions) always wins; condensed Strunk's *Elements of Style* only fills where the profile has no signal, and never overrides an observed trait (README.md:156-162).
- **Draft-only, never send** — every generator (doc/email/chat/rewrite) produces a draft; none send, publish, or post on the user's behalf (README.md:9). Sending/publishing stays a human action.
- **Harvested and pasted content is data, never instructions** — voice-email (reply threads) and voice-harvest (source content) are the two real prompt-injection surfaces; both treat everything they read as style data and never act on instruction-shaped strings found in it (README.md:170).
- **Consent-per-source, read-only mining** — voice-harvest reads Claude chats, Gmail, Slack, or Notion only with per-source consent, filters for owner-only authorship, and strips LLM-generated content via a two-pass baseline before it ever touches the profile (README.md:7).

*(High confidence — all five are stated directly in README.md's "Design rules" section or equivalent; none are inferred.)*

## Feature tracker

Issue tracker: [GitHub Issues](https://github.com/jacquardlabs/voice-suite/issues)

The tracker owns individual features and fixes. The eight skills themselves are the stable capability surface:

| Skill | Role |
|---|---|
| `voice-harvest` | Mines writing from Claude chat history, Gmail, Slack, or Notion; builds and refreshes the profile |
| `voice-profile` | Data layer — global + per-register traits, exemplars, anti-patterns, Strunk-exemption list; shared fidelity procedure |
| `voice-doc` | Generates long-form prose (docs, memos, proposals, posts) |
| `voice-email` | Generates email drafts |
| `voice-chat` | Generates short-form messages (Slack, DM, text) |
| `voice-rewrite` | Rewrites existing text into the user's voice |
| `voice-tune` | Learns from user edits to generated drafts; patches the profile after a repeated pattern, with confirmation |
| `voice-card` | Compiles the installed profile into a portable ~300-word prompt block for other AI surfaces |

All eight are shipped (README.md:185, "All 8 drafted").

*(High confidence — README.md status table, cross-checked against `skills/` directory contents.)*

## Critical user journeys

**1. First harvest.** Trigger: user runs `/voice-harvest` or says "learn my writing voice." Steps: skill asks which sources to read → mines only the user's own text → filters AI-generated content via the two-pass baseline → shows extracted samples for approval → writes the profile. Outcome: a populated voice profile, ready for the generators. Takes 5–15 minutes; run once, re-run anytime to add new writing (README.md:78-95).

**2. Generate a draft.** Trigger: user asks for a doc, email, chat message, or a rewrite of pasted text. Steps: the matching generator (voice-doc/email/chat/rewrite) reads the installed profile → applies voice-first, craft-fills-silence layering (long-form only) → drafts. Outcome: a draft in the user's voice, ready for the user to send/publish themselves (README.md:97-106).

**3. Tune from an edit.** Trigger: user has a generated draft and their own revised version. Steps: user pastes both and runs `/voice-tune` → the skill extracts what changed (voice patterns only, not content) → asks whether to promote each change to a standing rule → patches the profile on confirmation. Outcome: the next draft in that register starts closer to what the user actually wanted (README.md:108).

*(High confidence — this is the README's own "First run" walkthrough, not an inference.)*

## What we're NOT building

- **No sending or publishing** — explicitly draft-only; the suite does not integrate with send/post APIs for any channel (README.md:9, "Draft-only — none send or publish").
- **No org/team-shared voice profile** — the harvest and profile model is single-user; nothing in the codebase models a shared or organizational voice. Proposal #11 (audience-conditional per-recipient variants) is still an unbuilt, ungated proposal, not committed scope — it varies *tone by recipient* for one user, which is different from a shared team profile.
- **No write-back on claude.ai web/Desktop** — voice-tune "identifies the changes but can't write back to the installed skill files directly" there; the user must re-upload `voice-profile.zip` manually (README.md:110). This is a documented platform limitation, not a product boundary — flagged here because it shapes what "done" means per surface.

*(Medium confidence — the first is explicit; the second and third are inferred from the absence of any multi-tenant or web-write code path plus the documented claude.ai constraint.)*

<!-- FILL IN: Are there other explicit non-goals — e.g., no support for languages other than English, no voice cloning for audio/speech (despite the plugin manifest's "voice, audio, dictation" keywords, which don't match anything actually built), no support for creative/fiction writing? -->

## Current known problems

Ordered by what a 2026-07-07 cross-project prompt audit (open issues #4-#7) treats as most user-impacting:

1. **Harvested profile data can be silently destroyed** — it's written into the plugin-managed skill directory; `/plugin update voice-suite` replaces that directory and destroys the harvested profile (the user's most expensive artifact: 5–15 min harvest plus every tune patch since). On claude.ai the write path doesn't exist at all — voice-tune's core loop is a no-op there (issue #4).
2. **Profile path resolution and the fidelity procedure are inconsistently duplicated** — one generator hardcodes a claude.ai-only path; the other three improvise resolution differently; the "shared" 6-step fidelity loop is restated in all four generators with disagreeing fallback sample counts; one generator has a dangling cross-skill file dependency (issue #5).
3. **No numeric evidence standards for harvested confidence** — "high/medium/low" confidence has no rubric or minimum sample count; a handful of chat messages can produce a fully-populated, seemingly-authoritative Traits section. voice-tune's overfitting guard ("require a repeated pattern") is also unenforceable across sessions since tune has no memory (issue #6).
4. **Routing edges leak and the AI-tells list is duplicated four times** — some content (e.g., short social posts) gets routed to the wrong generator/register; the notes-vs-draft boundary between voice-doc and voice-rewrite is undefined; "fix the tone" over-promises in voice-rewrite; four hand-rolled AI-tells lists have drifted out of sync (issue #7).

*(High confidence — these are the project's own recorded findings, not inferred from code smell.)*

## Business model

No monetization logic found in the codebase. This is an MIT-licensed (LICENSE), open-source Claude plugin distributed via the Jacquard Labs marketplace and direct GitHub install (README.md:14-28) — no pricing, billing, plan-gating, or usage-quota code exists anywhere in `skills/`.

*(High confidence — absence is easy to verify; no billing integration, no plan-check logic, no pricing copy anywhere in the repo.)*
