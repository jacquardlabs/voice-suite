# Voice Suite

Seven Claude Skills that harvest your writing voice from text you actually wrote, then draft, rewrite, and refine prose in that voice.

## Installation

These skills work on two different Claude surfaces, each with its own install method.

---

### Option A — Claude (chat interface)

This covers the **Claude.ai website** and the **Claude Desktop app** (downloaded from [claude.ai/download](https://claude.ai/download)). You need a Claude account with a Pro or Max subscription.

Skills are uploaded as ZIP files, one per skill.

**1. Download this repo.**

Click **Code → Download ZIP** on this page and unzip it. You'll have a `voice-suite` folder.

**2. Zip each skill folder.**

Open the `voice-suite/skills/` folder. You'll see 7 subfolders. Compress each one individually:

- **Mac:** right-click the folder → Compress
- **Windows:** right-click the folder → Send to → Compressed (zipped) folder

You should end up with 7 ZIP files: `voice-harvest.zip`, `voice-profile.zip`, `voice-doc.zip`, `voice-email.zip`, `voice-chat.zip`, `voice-rewrite.zip`, `voice-tune.zip`.

**3. Upload each ZIP.**

In Claude (web or Desktop): click your account name → **Customize** → **Skills** → **+** → **Upload a skill**. Upload each ZIP in turn.

That's it. Skills activate automatically when Claude recognizes a matching request — or type `/skill-name` to invoke one directly.

---

### Option B — Claude Code

This covers the **Claude Code CLI**, the **Claude Code Desktop app**, and the **VS Code / JetBrains extensions**. All four share the same install directory. You need a Claude account with a Pro or Max subscription (or API access).

**1. Download this repo.**

If you have git:
```bash
git clone https://github.com/jacquardlabs/voice-suite.git
```
Otherwise: click **Code → Download ZIP** on this page and unzip it.

**2. Create your skills directory** (skip if it already exists).

Mac / Linux:
```bash
mkdir -p ~/.claude/skills
```
Windows (Command Prompt):
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

All 7 skills are immediately available — no restart required. Type `/skill-name` to invoke any of them.

---

## First run

Run these in order the first time. After that, use whichever generation skill you need.

**Step 1 — Build your voice profile.**

Type `/voice-harvest` (or just say "learn my writing voice" — Claude will pick it up).

The skill will ask which sources to read, mine only your own text, filter out AI-generated content, show you the extracted samples for approval, and write your profile. Takes 5–15 minutes depending on how much source material is available. You only need to do this once; run it again later to incorporate new writing.

What's available as a source depends on the surface:

| Source | Claude (web / Desktop) | Claude Code |
|---|---|---|
| Claude chat history | Paste samples manually | Full search via built-in tools |
| Gmail | If Gmail connector is enabled¹ | If Gmail connector is enabled¹ |
| Google Drive | If Drive connector is enabled¹ | If Drive connector is enabled¹ |
| Slack | Not available as a data source | Requires Slack MCP server |
| Notion | Not available as a data source | Requires Notion MCP server |
| Local files | Not available | Requires filesystem MCP server |

¹ Enable connectors on Claude.ai at account menu → **Customize** → **Connections**.

Voice-harvest handles missing sources gracefully — it tells you what isn't connected and works with what is. If no connectors are available, it will ask you to paste a few samples of your writing directly.

**Step 2 — Use a generation skill.**

| What you want to do | Say or type |
|---|---|
| Write a doc, memo, proposal, blog post | `/voice-doc` or "write a doc about…" |
| Draft or reply to an email | `/voice-email` or "draft a reply to this" |
| Write a Slack message, DM, or text | `/voice-chat` or "draft a Slack message to…" |
| Rewrite AI-generated text in your voice | `/voice-rewrite` or "make this sound like me" |

Describe what you need after invoking the skill, or paste the content you want rewritten. The skill reads your installed profile and drafts in your voice.

**Step 3 — Tune from your edits.**

When you revise a draft before sending it, paste both the original draft and your revised version into Claude and type `/voice-tune`. It identifies what changed (voice patterns only, not content), asks whether to make each change a standing rule, and updates your profile. Over time this sharpens the drafts toward how you actually write.

> **Note for Claude (web / Desktop) users:** voice-tune identifies the changes and tells you exactly what to update in your profile, but on this surface it can't write directly to the installed skill files. Apply the suggested edits by re-uploading an updated `voice-profile.zip`.

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
