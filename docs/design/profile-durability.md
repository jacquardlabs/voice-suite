# Design: Separate profile data from the plugin-managed skill directory

Story slug `profile-durability`, epic `audit-fixes`. Source: issue #4. This
design covers only this story's acceptance criteria — durable, per-platform
profile storage; one canonical resolution-order string quoted verbatim by
every consumer; and moving `voice-profile/SKILL.md`'s global-traits content
into `references/global.md`. It does not touch the fidelity-procedure
duplication, evidence/confidence rubric, or AI-tells consolidation — those are
issues #5 (remainder), #6, and #7, scheduled as separate stories in this epic.

## Problem & persona

Primary persona (PRODUCT.md): "A Claude user (Claude Code CLI/Desktop/IDE, or
claude.ai web/Desktop) who writes routinely across registers — long-form
docs, email, and chat/Slack — and wants AI-assisted drafts that read as
theirs, not as Claude's." Their job-to-be-done, per the same section: get "a
first draft that needs little or no voice-editing, only content edits" —
which only works if the harvested profile the drafts are checked against is
still there.

PRODUCT.md's own "Current known problems" ranks this first: "Harvested
profile data can be silently destroyed — it's written into the plugin-managed
skill directory; `/plugin update voice-suite` replaces that directory and
destroys the harvested profile (the user's most expensive artifact: 5–15 min
harvest plus every tune patch since). On claude.ai the write path doesn't
exist at all... voice-tune's core loop is a no-op there" (issue #4).

Today `voice-harvest` writes the populated profile into
`voice-profile/SKILL.md` (global traits) and `voice-profile/references/*.md`
(register files) — files that live inside the installed skill's own
directory. On the plugin/marketplace install path (README's primary,
documented channel), that directory is entirely replaced by `/plugin update`.
Nothing distinguishes "skill code" from "the user's data" on disk, so an
update that should only ship new skill logic also wipes the one artifact the
user spent real time building. This directly undercuts the persona's
job-to-be-done: after any update, drafts silently regress to unprofiled,
"read as Claude's" prose until the user notices and re-harvests from
scratch — repeating the 5–15 minute cost, potentially more than once.

This design serves PRODUCT.md's lead principle, "**Profile over everything**"
— that principle only holds if the profile persists long enough to keep being
consulted. A profile that gets wiped on every update isn't "everything," it's
"until the next release."

## Proposed design

**Separate the data plane from the skill plane.** `voice-profile` the skill
keeps shipping the contract (`_format.md`), the shared fidelity procedure, and
empty templates — nothing it ships is ever the live data. The live,
harvested/tuned profile lives in a directory outside any plugin- or
skill-managed path, resolved the same way by every consumer via one
literal, identical block of text (below).

### Directory layout

Skill plane (ships with the plugin, replaced wholesale on update — this is
fine, because nothing here is user data anymore):

```
skills/voice-profile/references/
├── _format.md      # unchanged — the per-register contract spec
├── global.md       # NEW — empty template, same "NOT YET POPULATED" convention as chat.md
├── longform.md      # empty template (unchanged in kind)
├── email.md          # empty template (unchanged in kind)
└── chat.md            # empty template (unchanged in kind)
```

Data plane (written by voice-harvest, patched by voice-tune, never touched by
`/plugin update` or a skill reinstall):

```
~/.claude/voice-profile/
├── global.md
├── longform.md
├── email.md
└── chat.md
```

`~/.claude/` is the Claude Code config directory (`~/.claude/` by default on
CLI, Desktop, and IDE — the same directory the README already documents as
shared across all four Claude Code surfaces for `~/.claude/skills/`).
`~/.claude/voice-profile/` sits as a sibling of `~/.claude/plugins/` (the
marketplace-managed cache) and `~/.claude/skills/` (the manual-install
tree) — outside both, so neither an update nor a reinstall of either kind
ever writes there.

claude.ai (web or Desktop app) has no path like this reachable at all: Skills
run from an uploaded ZIP with no writable location that outlives the
conversation. For that surface, the installed skill's own `references/`
folder is the *only* copy that exists, so it doubles as both the read
location and the (session-only) write location — this is the existing,
already-documented workaround (README: "voice-tune identifies the changes but
can't write back... re-upload `voice-profile.zip`"), now formalized as step 2
of the resolution order below instead of a one-off footnote.

### The canonical resolution-order string

One block of text, quoted **byte-identical** — not paraphrased, not
summarized — in `voice-doc`, `voice-email`, `voice-chat`, `voice-rewrite`,
`voice-harvest`, and `voice-tune` (six files), and stated once more as the
authoritative copy in `voice-profile/SKILL.md` itself. A grep for this
text's opening line must return exactly seven hits with identical bodies —
that's the acceptance check. The pre-fix bug this replaces is literally a
generator (`voice-doc`) hardcoding a claude.ai-only path
(`/mnt/skills/user/voice-profile/`) as if it were universal; the string below
is deliberately platform-agnostic so no consumer needs to special-case a
surface again:

> **Resolving the profile.** Find the profile directory by checking, in
> order, and using the first that resolves:
>
> 1. `~/.claude/voice-profile/` (the Claude Code config dir, `~/.claude/` by
>    default) — the stable, non-plugin-managed profile directory shared by
>    Claude Code CLI, Desktop, and IDE. No plugin-managed or skill-managed
>    path points here, so `/plugin update` and reinstalls never touch it.
>    voice-harvest creates it on first run wherever this path is reachable,
>    and always writes here afterward.
> 2. This skill's own installed `references/` folder — the claude.ai (web or
>    Desktop app) fallback, since no path outside the uploaded skill bundle
>    persists between sessions there. Step 1 simply won't resolve on
>    claude.ai (no such filesystem path exists there), so this is a plain
>    fall-through, not a platform check. Writes here are session-only: to
>    keep a harvest or tune change, the user must download and re-upload an
>    updated `voice-profile.zip`.
> 3. If the resolved directory's files are still the empty shipped
>    templates, no profile exists yet. Fall back to this skill's own ad-hoc
>    session profile from pasted samples, or point the user to voice-harvest.
>
> Read `global.md` plus the matching register file (`longform.md` /
> `email.md` / `chat.md`) from whichever directory step 1 or 2 resolved to —
> never mix a `global.md` from one location with a register file from the
> other.

### What changes in each file

- **`voice-profile/SKILL.md`** — the `## Global traits` section (currently
  populated in place by voice-harvest) is deleted from this file entirely and
  replaced by a short pointer to `references/global.md`, plus the canonical
  resolution string as a new `## Resolving the profile` section. The YAML
  frontmatter (`name`/`description`) is untouched either way — issue #4's own
  text calls the rewritten section "frontmatter" loosely; the actual load-
  bearing routing metadata was never the problem, the risk was an automated
  write touching the same file at all. Moving the data out removes that
  file from voice-harvest's write path completely. The fidelity procedure,
  anti-leakage checklist, and "Important" notes are unchanged.
- **`voice-doc`, `voice-email`, `voice-chat`, `voice-rewrite`** — each
  skill's "load the voice" step changes from reading
  `voice-profile/SKILL.md` (global traits) + its own `references/X.md`
  directly, to: resolve the directory via the canonical string, then read
  `global.md` + its own register file from that resolved directory. This is
  the change that touches all four generators, not an optional cleanup — it
  is the direct consequence of moving both the data location (criterion 1)
  and the global-traits file (criterion 2). It also retires voice-doc's
  existing hardcoded `/mnt/skills/user/voice-profile/` path, which was
  claude.ai-only and wrong for Claude Code users.
- **`voice-harvest`** — the Output step resolves (and, per step 1, creates)
  the profile directory via the same canonical string, then writes
  `global.md`, `longform.md`, `email.md`, and `chat.md` there. It no longer
  writes into `voice-profile/SKILL.md` at all.
- **`voice-tune`** — the "patch the profile" step resolves the directory the
  same way before patching whichever file (`global.md` or a register file)
  the edit's pattern belongs to.
- **`README.md`** — gains a documented, per-platform statement of where
  profile data lives: `~/.claude/voice-profile/` for Claude Code (CLI,
  Desktop, IDE), and "the installed skill's own files, re-uploaded as
  `voice-profile.zip` to persist a change" for claude.ai (web/Desktop app).
  This satisfies criterion 1 (documented per platform) without inventing a
  new mechanism — it's the same two facts as the resolution string, stated
  for a human reader instead of a consuming skill.

## User journey

**First harvest, Claude Code.** User runs `/voice-harvest`. After the consent
and exemplar-approval steps, harvest resolves the profile directory (step 1
of the canonical order: `~/.claude/voice-profile/` doesn't exist yet, so it's
created) and writes the four files there. This is CUJ #1 ("First harvest") —
unchanged from the user's point of view; the only difference is *where* the
result lands on disk, which the user never has to know.

**A plugin update ships.** Time passes; `/plugin update voice-suite` pulls a
new release. Under the current design, this replaces the entire
`voice-profile` skill directory, including the harvested data living inside
it — CUJ #2 ("Generate a draft") starts silently degrading, back to
unprofiled prose, with no warning. Under this design, the update replaces
only the skill plane (`skills/voice-profile/references/*.md`, still empty
templates) — `~/.claude/voice-profile/` is untouched, so the next
`/voice-doc` or `/voice-email` resolves the same populated directory it
always did. The user notices nothing changed.

**Tune, Claude Code.** User pastes a draft and their edited version, runs
`/voice-tune`. Tune resolves the same directory (already exists, step 1) and
patches the relevant file in place — CUJ #3 ("Tune from an edit") unchanged.

**First harvest and tune, claude.ai.** User uploads the seven skill ZIPs,
runs `/voice-harvest`. Step 1 of the resolution order doesn't resolve (no
such filesystem path on claude.ai), so harvest writes into the installed
`voice-profile` skill's own `references/` folder — this session only. The
skill tells the user, as today, that persisting this past the conversation
means downloading and re-uploading an updated `voice-profile.zip`. Later,
`/voice-tune` resolves the same in-skill location and patches it the same
way, with the same re-upload requirement stated at delivery. Nothing about
this user's workflow gets harder than it already is — the difference is that
it's now a documented, first-class step of the same resolution order every
other skill uses, rather than one generator's special-cased hardcoded path.

## Out of scope

- **The fidelity procedure's duplicated 6-step loop and disagreeing ad-hoc
  fallback sample counts** (voice-doc says "2–4 samples," voice-email "2–3,"
  voice-chat "a couple," voice-rewrite "2–4 pasted samples") — issue #5's
  remaining territory, scheduled as the `fidelity-consistency` story. This
  design only unifies *where the profile is resolved from*, not the
  drafting procedure itself.
- **Quantified evidence/confidence rubric for harvested traits** — issue #6,
  the `evidence-standards` story.
- **AI-tells vocabulary consolidation and routing edges** — issue #7, the
  `routing-tells-consolidation` story.
- **`voice-card-export` (#10) and the `voice-check` fidelity scorer (#9)** —
  explicitly deferred by the epic goal until their prerequisites (including
  this story) land.
- **A dated `history/` snapshot ledger under the profile directory.** Issue
  #4 names this as a "bonus" this design happens to enable (a stable
  directory makes dated snapshots trivial to add later) — but no story's
  acceptance criteria requires it yet, so it isn't built here. Left for
  whichever future story needs voice-tune's cross-session pattern memory
  (issue #6 territory).
- **A migration/backfill subsystem for profiles harvested before this fix.**
  See Open Questions — a minimal, targeted mitigation is proposed there, but
  a general migration tool is not in scope.
- **New claude.ai persistence mechanisms** (e.g., Projects/memory
  integration). The claude.ai fallback formalizes the *existing*,
  already-documented re-upload workaround; it does not add a new connector
  or storage integration, which would need its own validation and consent
  model.
- **Windows/Linux-specific path handling beyond the existing convention.**
  The README already documents `~/.claude/skills/` as shared across
  Mac/Linux/Windows (via `%USERPROFILE%`); `~/.claude/voice-profile/` follows
  the identical, already-established convention rather than introducing new
  per-OS logic.

## Alternatives considered

- **Add a "preserve these paths" allowlist to the plugin's update mechanism**
  instead of relocating the data. Rejected: no such mechanism exists in
  Claude Code's plugin system today (an update replaces the plugin's managed
  directory wholesale); building one would mean changing product behavior
  outside this repo's control, for a problem this story can solve entirely
  within the repo by choosing a different path.
- **Version-scoped backup-then-restore around each update** (snapshot the
  skill directory before update, restore data after). Rejected: more moving
  parts than simply never writing user data into an update-managed path in
  the first place — violates "prefer the simplest approach first." It would
  also need to hook the update process itself, which this plugin doesn't
  control.
- **External storage (a small database, cloud sync, or an MCP-backed store)**
  for the profile. Rejected: introduces a new runtime dependency into a
  project whose entire architecture today is plain markdown Skills with no
  application code to run or maintain (CLAUDE.md: "no application source... no
  language to lint") — disproportionate to a single-user, prompt-only
  product, and adds a connector/consent surface this story doesn't need.
- **Build a claude.ai persistence integration now** (e.g., writing to
  Projects/memory instead of relying on re-upload). Rejected as premature:
  not confirmed to be a reliably scriptable target for a Skill today, and the
  existing re-upload workaround is already documented and works; formalizing
  it as step 2 of one resolution order is strictly simpler than standing up
  a new integration, and can be revisited later if claude.ai gains a better
  primitive.
- **Per-skill hardcoded paths, chosen by each generator for "its" platform.**
  This is the status quo bug (voice-doc's `/mnt/skills/user/...`) rather than
  a real alternative, but worth naming as rejected explicitly: it requires
  every consumer to know which platform it's running on and breaks the
  moment a consumer's assumption (as voice-doc's did) is wrong for the
  surface actually in use. The ordered, platform-agnostic fallback needs no
  platform detection at all — a step either resolves or it doesn't.

## Open questions

1. **Upgrade-transition data loss for existing (pre-fix) profiles.** A user
   who already harvested under the old scheme has their data sitting inside
   the currently-installed `voice-profile` skill directory. The moment this
   fix ships and that skill directory is next replaced by `/plugin update`,
   the *old* data is wiped before ever being read under the *new* scheme —
   the exact failure this story exists to prevent, potentially triggered one
   last time by the fix itself. Minimal proposed mitigation, for the gate to
   decide on rather than a committed build item: when `~/.claude/voice-profile/`
   doesn't exist yet, voice-harvest checks once whether the currently-
   installed skill's `references/` folder holds populated files (not the
   empty template) and, if so, copies them into the new durable directory
   before treating the run as a fresh harvest. Residual risk: a user whose
   *next* `/plugin update` lands before they ever run harvest or tune again
   post-fix loses the old data regardless — same outcome as today, not a
   regression this design introduces, just not fully closed by it either.
2. **Is `~/.claude/` always the right root?** This design assumes the
   Claude Code config directory is `~/.claude/` by default, per the README's
   existing documentation of `~/.claude/skills/`. If Claude Code supports an
   environment-variable override of that root (unverified in this repo), the
   resolution string's step 1 may need to reference the override instead of
   a hardcoded path. Flagging rather than asserting either way.
3. **Exact README placement and wording** for the per-platform data-path
   documentation (new subsection vs. folding into "Install" or "First run")
   is left to the build worker's judgment; the contract here is that the two
   facts (Claude Code path, claude.ai fallback) are stated accurately
   somewhere a user would find them, not a specific heading or location.
