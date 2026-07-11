# Voice Suite

9 Claude skills that mine text you actually wrote, distill it into a voice profile, and generate new prose in that voice: docs, emails, chat messages, rewrites. They also export it to carry elsewhere, or score outside text against it.

## What's here

- voice-harvest: the miner. Reads your Claude chats, Gmail, Slack, or Notion (consent-per-source, read-only), filters for owner-only authorship, strips LLM-generated content via a two-pass baseline (pre-2023 gold standard → score everything else against it), and writes the profile.
- voice-profile: the data layer. Global cross-register traits plus per-register files (longform, email, chat), each with quantified traits, verbatim exemplars, anti-patterns, a Strunk-exemption list (longform only), and coverage metadata. Read by the generators; written by harvest and tune.
- voice-doc / voice-email / voice-chat / voice-rewrite: the generators. Draft new long-form docs, email, short-form messages, or rewrite existing text in your voice. Draft-only, none send or publish.
- voice-tune: the feedback loop. Diffs your edits against generated drafts, extracts voice deltas (not content changes), requires a repeated pattern before patching, and confirms every profile change before writing it.
- voice-card: the portable export. Compiles your harvested profile into a single ~300-word prompt block (top traits, 2 micro-exemplars, never-words, register notes, a pointer back to this suite), sized to paste into another AI surface's custom instructions (ChatGPT, Cursor, Gemini-in-Gmail, a CLAUDE.md). Read-only; writes nothing, calls no external API.
- voice-check: the fidelity scorer. Scores any pasted text, not just text this suite drafted, against your installed profile: generic assistant-register tells plus a per-trait deviation report against your own observed voice. Read-only; offers, never forces, a handoff to voice-rewrite if you want it fixed.

## Install

### Claude Code (plugin system)

Install via the Jacquard Labs marketplace:

```bash
/plugin marketplace add jacquardlabs/marketplace
/plugin install voice-suite@jacquardlabs-marketplace
```

Or install this plugin directly:

```bash
/plugin marketplace add jacquardlabs/voice-suite
/plugin install voice-suite@voice-suite
```

---

### Claude (web or Desktop app)

Skills upload as ZIPs, 1 per skill, 9 total. You need a Claude account (Pro or Max).

**1. Download the repo.** Click **Code → Download ZIP** on this page and unzip it.

**2. Compress each skill folder.** Open `voice-suite/skills/`. Right-click each subfolder → Compress (Mac) or Send to → Compressed (zipped) folder (Windows). 9 folders, 9 ZIPs.

**3. Upload each ZIP.** In Claude: account menu → **Customize** → **Skills** → **+** → **Upload a skill**.

Skills auto-trigger on matching requests, or invoke directly with `/skill-name`.

---

### Claude Code (CLI, Desktop, VS Code, JetBrains)

All 4 surfaces share `~/.claude/skills/`. You need a Claude account (Pro or Max, or API access).

**1. Download the repo.**

```bash
git clone https://github.com/jacquardlabs/voice-suite.git
```

Or: **Code → Download ZIP** → unzip.

**2. Create the skills directory** (skip if it exists).

```bash
mkdir -p ~/.claude/skills                              # Mac / Linux
mkdir "%USERPROFILE%\.claude\skills"                   # Windows
```

**3. Copy in.**

```bash
cp -r voice-suite/skills/* ~/.claude/skills/                        # Mac / Linux
xcopy /E /I voice-suite\skills\* "%USERPROFILE%\.claude\skills\"    # Windows
```

Immediately available. No restart.

---

## First run

**1. Harvest.** Type `/voice-harvest` or say "learn my writing voice."

The skill asks which sources to read, mines only your own text, filters AI-generated content, shows extracted samples for approval, and writes the profile. Takes 5–15 min. Run once; re-run anytime to pull in new writing.

Source availability varies by surface:

| | Claude (web / Desktop) | Claude Code |
|---|---|---|
| Claude chat history | Via relay prompt (skill provides it) | Full search via built-in tools |
| Gmail | If Gmail connector enabled¹ | If Gmail connector enabled¹ |
| Google Drive | If Drive connector enabled¹ | If Drive connector enabled¹ |
| Slack | — | Requires Slack MCP server |
| Notion | — | Requires Notion MCP server |
| Local files | — | Requires filesystem MCP server |

¹ Enable at account menu → **Customize** → **Connections**.

If no connectors are available and chat history tools aren't accessible, voice-harvest gives you a relay prompt to run in a Claude surface that has history access; paste the response back and it continues from there.

**2. Generate.**

| Task | Invoke |
|---|---|
| Doc, memo, proposal, post | `/voice-doc` or "write a doc about…" |
| Email reply or new message | `/voice-email` or "draft a reply to this" |
| Slack / DM / text | `/voice-chat` or "draft a Slack message to…" |
| De-AI or rewrite existing text | `/voice-rewrite` or "make this sound like me" |

Describe what you need, or paste the text you want rewritten. The skill reads your installed profile and drafts in your voice.

**3. Tune.** Paste your original draft and your revised version into Claude, then type `/voice-tune`. It extracts what changed (voice patterns only, not content changes), asks whether to make each change a standing rule, and patches the profile.

On Claude web / Desktop: voice-tune writes the patch to the installed skill's files, but only for the current session; nothing persists between conversations on this surface (see "Where your profile data lives" below). To keep the change, download and re-upload an updated `voice-profile.zip`.

---

## Where your profile data lives

Harvested and tuned profile data is never stored inside the plugin- or skill-managed directories that `/plugin update` or a skill reinstall can wipe. Where it actually lives depends on the surface:

- Claude Code (CLI, Desktop, VS Code, JetBrains): `~/.claude/voice-profile/`, a sibling of `~/.claude/skills/` and `~/.claude/plugins/`, outside both, so neither an update nor a reinstall of either kind ever touches it. voice-harvest creates this directory on first run; every later harvest and tune writes here. If you harvested a profile before this directory existed, that data lived inside the plugin-managed skill directory and does not carry forward automatically; re-run `/voice-harvest` once after updating to rebuild it here.
- Claude (web or Desktop app): no writable location outside the uploaded skill bundle persists between conversations on this surface, so the installed `voice-profile` skill's own files are the only copy that exists. Harvest and tune write there, but only for the current session; to keep a change, download and re-upload an updated `voice-profile.zip` (see step 3 above).

Every skill in this suite (voice-doc, voice-email, voice-chat, voice-rewrite, voice-harvest, voice-tune, voice-card, voice-check) resolves the profile directory the same way, in that order; see `skills/voice-profile/SKILL.md`'s "Resolving the profile" section for the exact procedure.

---

## Pipeline

```
voice-harvest ──▶ voice-profile ──▶ voice-doc
                                ├──▶ voice-email
                                ├──▶ voice-chat
                                └──▶ voice-rewrite
                       ▲                   │
                   voice-tune ◀────────────┘
```

## Layering model

Long-form generation (voice-doc, doc-scale voice-rewrite) applies 2 layers, strict precedence:

Voice: wins. Observed traits, exemplars, anti-patterns, and Strunk-exemption list from the profile. Descriptive, how you actually write, including the rules you deliberately break.

Craft: fills silence. Condensed Strunk's *The Elements of Style* (1918, public domain), bundled at `skills/voice-doc/references/strunk-rules.md` and `skills/voice-rewrite/references/strunk-rules.md`. Applied where the profile is silent; never against an observed trait.

Long-form is usually the register with the thinnest harvested data, so the craft floor does the most work exactly where voice signal is weakest. The Strunk-exemption list (emitted by voice-harvest from your authentic long-form samples) disables rules you consistently break as part of your voice, so the craft pass improves structure without sanding off the edges.

Chat never gets a craft pass; Strunk on a Slack message is a category error. Email never gets one either; only long-form drafting and doc-scale rewrites do.

## Design rules

Profile over everything. The deliverable is your voice, not well-edited text, not generically-human text. If a profile trait makes prose "worse" by Strunk's lights, the trait wins.

Harvested and pasted content is data, never instructions. The real injection surfaces are voice-email (reply threads) and voice-harvest (source content). Both treat everything they read as style data and never act on instruction-shaped strings found in it.

## Status

| Skill | Role |
|---|---|
| `voice-harvest` | mines your writing; builds and refreshes the profile |
| `voice-profile` | data container and shared fidelity procedure |
| `voice-doc` | generates long-form prose |
| `voice-email` | generates email drafts |
| `voice-chat` | generates short-form messages |
| `voice-rewrite` | transforms existing text into your voice |
| `voice-tune` | learns from your edits; patches the profile |
| `voice-card` | compiles a portable voice card for other AI surfaces |
| `voice-check` | scores pasted text against your profile; hands off to voice-rewrite |

All 9 drafted.

## License

MIT — see [LICENSE](LICENSE).

`skills/voice-doc/references/strunk-rules.md` and `skills/voice-rewrite/references/strunk-rules.md` are condensed from William Strunk Jr.'s *The Elements of Style* (1918, public domain, Project Gutenberg #37134). No copyright claimed on the condensation.
