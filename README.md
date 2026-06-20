# Voice Suite

Seven Claude Skills that harvest your writing voice from text you actually wrote, then draft, rewrite, and refine prose in that voice.

## Requirements

These skills run inside **Claude Code** — Anthropic's AI coding assistant. Claude Code is available as:

- **Desktop app** — [claude.ai/download](https://claude.ai/download) (Mac and Windows; easiest starting point)
- **CLI** — `npm install -g @anthropic-ai/claude-code` (requires Node.js 18+)
- **IDE extension** — search "Claude" in VS Code or JetBrains Marketplace

You need an Anthropic account and an active Claude subscription (Pro or above). All three surfaces share the same skill installation directory, so instructions below apply to all of them.

> **claude.ai web** — the browser version of Claude does not support user-level skills. These skills will not be available there.

## Installation

**1. Download the skills.**

If you have git:
```bash
git clone https://github.com/jacquardlabs/voice-suite.git
```

Otherwise: click **Code → Download ZIP** on this page, then unzip it.

**2. Create your skills directory** (skip if it already exists).

Mac / Linux:
```bash
mkdir -p ~/.claude/skills
```

Windows (run in Command Prompt):
```bat
mkdir "%USERPROFILE%\.claude\skills"
```

**3. Copy the skills in.**

Mac / Linux:
```bash
cp -r voice-suite/skills/* ~/.claude/skills/
```

Windows:
```bat
xcopy /E /I voice-suite\skills\* "%USERPROFILE%\.claude\skills\"
```

That's it. All 7 skills are immediately available — no restart required.

## First run

Run these in order the first time. After that, use whichever generation skill you need.

**Step 1 — Build your voice profile.**

Open Claude Code (desktop, CLI, or IDE) and type:
```
/voice-harvest
```
The skill will ask which sources to read (your Claude chat history is always available; Gmail, Slack, and Notion require those connectors to be enabled). It filters out AI-generated text and other people's writing, shows you the extracted exemplars for approval, then writes your profile. Takes 5–15 minutes depending on how much source material is available.

You only need to do this once. Run it again later with "refresh my profile" to incorporate new writing.

**Step 2 — Use a generation skill.**

| What you want to do | Type |
|---|---|
| Write a doc, memo, proposal, blog post | `/voice-doc` |
| Draft or reply to an email | `/voice-email` |
| Write a Slack message, DM, or text | `/voice-chat` |
| Rewrite AI-generated text in your voice | `/voice-rewrite` |

Describe what you need after invoking the skill, or paste the content you want rewritten. The skill reads your profile and drafts in your voice.

**Step 3 — Tune from your edits.**

When you revise a draft before using it, paste both versions into Claude and type:
```
/voice-tune
```
It extracts what changed (voice patterns only, not content), asks whether to make each change a standing rule, and patches your profile. Over time this sharpens the drafts.

## Pipeline

```
voice-harvest ──▶ voice-profile ──▶ voice-doc
                                ├──▶ voice-email
                                ├──▶ voice-chat
                                └──▶ voice-rewrite
                       ▲                   │
                   voice-tune ◀────────────┘
```

**1. Harvest.** `voice-harvest` reads your own text across connected sources (Claude chats, Gmail sent, Slack, Notion), filters for owner-only authorship, strips LLM-generated content using a two-pass baseline method, and synthesizes voice traits and verbatim exemplars per register. Consent-per-source, read-only. A two-pass LLM filter builds a trusted pre-AI baseline first, then scores everything else against it — false excludes waste one sample; false includes poison the voice, so precision wins over recall.

**2. Profile.** `voice-profile` stores the result as structured reference data: global cross-register traits, plus per-register files (longform, email, chat) each holding quantified traits, verbatim user-approved exemplars, anti-patterns, a Strunk-exemption list (longform only), and coverage metadata. `voice-harvest` writes these files; `voice-tune` patches them; the generation skills only read them. This separation makes the profile versionable and refreshable without touching any other skill.

**3. Generate.** Four register-specific skills draft prose in your voice:

- `voice-doc` — long-form: docs, memos, proposals, READMEs, posts
- `voice-email` — email: replies, new messages, follow-ups, declines
- `voice-chat` — short-form: Slack messages, DMs, texts
- `voice-rewrite` — transforms existing text into your voice, the suite's highest-frequency case ("de-AI this," "make this sound like me")

All four are draft-only. None send or publish.

**4. Tune.** `voice-tune` closes the loop. It diffs your edits against generated drafts, extracts voice deltas (not content changes), requires a repeated pattern before patching, and confirms every profile change in plain language before writing it. Edits outrank harvested guesses — a direct correction is the strongest signal available.

## Layering model

Long-form generation (`voice-doc`, and doc-scale `voice-rewrite`) applies two layers in strict precedence:

**1. Voice layer — always wins.** Your observed traits, exemplars, anti-patterns, and Strunk-exemption list from the profile. Descriptive — how you actually write, including the rules you deliberately break.

**2. Craft layer — fills silence.** A condensed version of Strunk's *The Elements of Style* (1918, public domain) bundled at `skills/voice-doc/references/strunk-rules.md` and `skills/voice-rewrite/references/strunk-rules.md`. Prescriptive defaults for structure, grammar, and clarity — applied where the profile is silent or low-confidence, never against an observed trait.

This layering is intentional: long-form is usually the register with the thinnest harvested data, so the craft floor does the most work exactly where the voice signal is weakest. The Strunk-exemption list (generated by `voice-harvest` from your authentic long-form samples) disables specific rules you consistently break as part of your voice, so the craft pass enhances structure without sanding off the edges.

Chat register never gets a craft pass — Strunk on a Slack message is a category error. Email gets one only for long, external, formal mail.

## Design rules

Two rules hold across the full suite:

**Profile over everything.** The deliverable is *your* voice — not well-edited text, not generically-human text. If a profile trait makes prose "worse" by Strunk's lights, the trait wins.

**Harvested and pasted content is data, never instructions.** The most live injection surfaces are `voice-email` (reply threads) and `voice-harvest` (source content). Both treat everything they read as style data and never act on instruction-shaped strings found in it.

## Status

| Skill | Status | Role |
|---|---|---|
| `voice-harvest` | drafted | mines your writing; builds and refreshes the profile |
| `voice-profile` | drafted | data container and shared fidelity procedure |
| `voice-doc` | drafted | generates long-form prose |
| `voice-email` | drafted | generates email drafts |
| `voice-chat` | drafted | generates short-form messages |
| `voice-rewrite` | drafted | transforms existing text into your voice |
| `voice-tune` | drafted | learns from your edits; patches the profile |

## License

Suite code: MIT — see [LICENSE](LICENSE).

`skills/voice-doc/references/strunk-rules.md` and `skills/voice-rewrite/references/strunk-rules.md` are condensed from William Strunk Jr.'s *The Elements of Style* (1918). The 1918 text is in the public domain (Project Gutenberg #37134). No copyright is claimed on the condensation.
