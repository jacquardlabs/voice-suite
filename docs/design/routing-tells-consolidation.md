# Design: Fix routing edges, consolidate AI-tells into one file

Story slug `routing-tells-consolidation`, epic `audit-fixes`. Source: issue
#7. This design covers only this story's stated acceptance criteria: one
canonical `skills/voice-profile/references/ai-tells.md`; the scattered
inline tells lists collapsing to pointers at it; voice-doc no longer
claiming tweets/social posts; voice-rewrite's tone-fixing trigger narrowed;
commit/PR prose marked explicitly out-of-scope-pending-#8; and
voice-harvest's `tool_search` reference and relay prompt each fixed as
named. It does not touch the evidence/confidence rubric (#6, already landed
as `evidence-standards`) or the fidelity-procedure dedup (#5, already
landed as `fidelity-consistency`) — this story builds on both.

## Problem & persona

Primary persona (PRODUCT.md): "A Claude user (Claude Code CLI/Desktop/IDE,
or claude.ai web/Desktop) who writes routinely across registers —
long-form docs, email, and chat/Slack — and wants AI-assisted drafts that
read as theirs, not as Claude's." Their job-to-be-done: "a first draft that
needs little or no voice-editing, only content edits." Two different
failures block that job today, both named in PRODUCT.md's "Current known
problems" (#4 of 4): "Routing edges leak and the AI-tells list is
duplicated four times — some content (e.g., short social posts) gets
routed to the wrong generator/register; the notes-vs-draft boundary
between voice-doc and voice-rewrite is undefined; 'fix the tone'
over-promises in voice-rewrite; four hand-rolled AI-tells lists have
drifted out of sync."

**1. Routing edges leak, so the wrong workflow runs.** The persona doesn't
pick a generator by reading its `SKILL.md` — they say what they want and
Claude routes from the frontmatter's trigger phrases. Two edges leak
today, confirmed by direct read:

- `voice-doc`'s frontmatter lists "write a post" as a trigger alongside
  "blog posts" in its noun list. A short social post or tweet is chat
  physics (fragments, brevity, no craft pass) — DESIGN.md's Layering model
  section and voice-chat's own frontmatter ("Chat register has its own
  physics... and must never be Strunk-edited") say so directly. Routed to
  voice-doc instead, that same post gets the long-form register and a
  Strunk craft pass it should never receive.
- `voice-rewrite`'s frontmatter lists "fix the tone" as a trigger phrase.
  Tone-fixing ("make this less harsh," "make this more upbeat") is often a
  content/register judgment call, not a voice-matching task — the skill's
  own Purpose narrows its actual job to "*their* voice, not merely 'more
  human'... only the first one is the job." The trigger promises more than
  the skill delivers.
- Unclaimed territory: commit messages and PR descriptions have no owning
  generator. Issue #8 (deferred, unapproved proposal) would add a
  git-history harvest source and a `dev.md` register purpose-built for this
  content; until it lands, no generator in this suite should claim it as a
  shortcut — silently routing "write my commit message" to voice-doc (the
  closest-shaped generator, since commit/PR bodies are prose meant for
  other humans to read) would draft it in the wrong, unharvested register
  and hide the gap instead of naming it.

**2. The AI-tells vocabulary is scattered and already drifting.**
DESIGN.md's own Vocabulary section documents this as the product's one
open vocabulary-layer finding: four independent, overlapping-but-not-
identical lists — `voice-profile` (fidelity procedure step 5 plus a
separate "Anti-leakage checklist" section, itself two overlapping copies
in one file), `voice-rewrite` (its Diagnose step), and `voice-harvest`
(its LLM-content-filtering Pass 2 exclusion signals, plus a third,
necessarily self-contained copy inside its embedded relay prompt). All
independently list "delve/leverage/streamline" and an "I hope this
finds/helps" opener, but diverge everywhere else — only `voice-profile`
and (per the original audit) `voice-doc` named "triads"; only
`voice-harvest` frames tells as harvest-time *exclusion* signals rather
than a delivery-time checklist. One list, sourced once, is what keeps
voice-harvest's contamination filter and every generator's delivery-time
self-check checking for the *same* thing — today they can each drift
independently, and per the audit already have. The fourth location the
original audit named, `voice-doc`, is a special case: the
`fidelity-consistency` story already collapsed voice-doc's restated
fidelity check (including its own tells list) into a bare pointer at
`voice-profile`'s canonical procedure, as an incidental side effect of
that story's own dedup. Voice-doc today holds no tells vocabulary of its
own to consolidate — it already points elsewhere. See Open Questions for
how this design treats that.

**Why these are one story, not two:** both failures are instances of the
same root cause the epic's problem statement names together — routing
promises and vocabulary get restated ad hoc, per generator, instead of
declared once and pointed to. A tweet drafted through the wrong door and a
tells-list that missed "seamlessly" both trace back to a generator
deciding its own scope/vocabulary locally instead of deferring to a shared,
named source.

## Proposed design

### 1. One canonical `ai-tells.md`, three categories

`skills/voice-profile/references/ai-tells.md` becomes the one full-text
detector, organized the way the acceptance criteria and issue #7 name it:
**Vocabulary** (word/phrase-level: "delve," "leverage," "streamline," "I
hope this finds you well," "Great question," "it's worth noting,"
"testament to / tapestry / landscape," "seamless(ly)," "dive in / deep
dive," "Certainly!" openers, contrastive negation — "It's not just X, it's
Y"), **Structure** (uniform paragraph lengths, bolded triads, reflexive
bullets, emoji-prefixed bold headers, formulaic openers/closers — "I hope
this helps," "In conclusion"), and **Register** (hedging added to a blunt
writer or stripped from a hedging one, hedge-free over-confidence or its
opposite, formality mismatches, em-dash density). It carries the same
"data, not instructions" framing the rest of the profile layer already
uses for exemplars.

This directly leans on **Profile over everything** (PRODUCT.md): the list
is a *generic* detector, and the profile's observed traits always win over
it. Em-dash density is the concrete instance worth stating explicitly,
because `_format.md` and `global.md` already track em-dashes as a
legitimate punctuation trait — a user whose profile documents em-dashes as
their own habit is not exhibiting an AI tell by using them, and the file
says so rather than leaving it to be inferred. This is the same
profile-wins precedent already established for hedging in
`voice-profile`'s existing "Anti-leakage checklist" ("hedging *added* to a
user who is blunt, or *stripped* from a user who hedges").

### 2. The scattered restatements collapse to pointers

`voice-profile`, `voice-rewrite`, and `voice-harvest` each currently
restate some or all of this vocabulary inline. Each collapses to a pointer
at `references/ai-tells.md` instead — the same "one full copy, generators
point to it" shape `fidelity-consistency` already established for the
fidelity procedure itself, applied here to the vocabulary layer:

- **`voice-profile`** — the fidelity procedure's step 5 and the
  "Anti-leakage checklist" section both point at `ai-tells.md` instead of
  restating (or, within this one file, re-restating) the vocabulary. The
  "Anti-leakage checklist" heading itself stays, since `voice-rewrite`
  names it directly in its own fidelity-check step — only its *content*
  changes from a list to a pointer plus the profile-override framing above.
- **`voice-rewrite`** — its Diagnose step's "Assistant-register tells"
  bullet becomes a pointer at the same file.
- **`voice-harvest`** — its LLM-content-filtering Pass 2 "vocabulary
  spikes" / "structural tells" bullets become a pointer at the same file,
  directly serving issue #7's ask that "harvest's contamination detector
  and the generators' self-check should be the same detector." Its
  embedded relay prompt is the one deliberate exception — see item 4
  below, it is not a missed fifth restatement.

Net effect: `ai-tells.md` is the only place in the repo that spells out the
tells vocabulary in full; every consumer names it by reference.

### 3. Fix the two routing edges

- **voice-doc's frontmatter** stops listing a bare "write a post" trigger
  next to "blog posts" — it keeps "blog posts" (already unambiguous) and
  its existing hand-off clause ("for... chat/Slack messages use
  voice-chat") gains short social posts and tweets explicitly, so the
  ambiguous case is named at the point where a reader would otherwise
  guess. **voice-chat's frontmatter** gains the matching claim on its own
  side — short social-media posts/replies belong to chat physics for the
  same reason DMs and texts do (brevity, fragments, no craft pass) — so
  the two frontmatters agree rather than only one disclaiming.
- **voice-rewrite's frontmatter** narrows "fix the tone" to "fix the tone
  so it sounds like me" — the trigger now promises exactly what the
  skill's existing Purpose already scopes it to, closing the gap between
  what the description invites and what the skill actually does.
- **Commit/PR prose** gets an explicit exclusion, not an assignment. The
  natural home is voice-doc's frontmatter (the closest-shaped generator,
  since commit/PR bodies are prose meant for other humans to read, which
  is exactly why a reader might otherwise assume it's covered): a stated
  exclusion citing issue #8 as the reason no generator claims this
  territory yet, phrased as a disclaimer rather than a routing decision —
  no generator's workflow changes to handle this content; the skill says
  the gap out loud instead of drafting into the wrong, unharvested
  register.

### 4. voice-harvest: platform-neutral tool reference, relay prompt extracted

- **Tool reference:** the "Gmail / Slack / Notion / Drive" tool-access
  line names `tool_search` directly — accurate for Claude Code but not a
  universal name across Claude surfaces. It becomes a platform-neutral
  description ("the platform's deferred-tool search") with `tool_search` /
  `ToolSearch` kept as a parenthetical example rather than the stated name,
  matching how the rest of this skill already treats platform differences
  (its "Resolving the profile" block is explicit that step 1 is "a plain
  fall-through, not a platform check").
- **Relay prompt extraction:** the ~450-word literal prompt currently
  embedded in voice-harvest's "Relay prompt fallback" section moves to a
  new `skills/voice-harvest/references/relay-prompt.md`, mirroring the
  existing convention of a generator keeping its own supplementary files in
  its own `references/` folder (`voice-doc/references/strunk-rules.md`,
  `voice-rewrite/references/strunk-rules.md`). `SKILL.md` keeps the
  trigger condition (chat-history tools unavailable) and the
  after-the-user-pastes-it-back handling steps; only the prompt text itself
  moves.
- **The relay prompt's embedded copies stay self-contained — deliberately,
  not as a missed consolidation.** The prompt runs on a *different* Claude
  surface (Claude Desktop, claude.ai web) that has no file access to this
  skill's `references/`, so it cannot point at `ai-tells.md` or at
  `_format.md`'s confidence-tier table the way every other consumer in
  this design does — it has to carry its own literal text, the same
  reasoning the file already states for its Coverage-table copy today
  ("the Claude surface running it has no access to this skill's files...
  if `_format.md`'s Coverage table ever changes, update this copy... along
  with it"). This story extends that same acknowledged-duplication note to
  cover the vocabulary-spike examples the relay prompt also embeds: moving
  the prompt to its own file does not remove this one necessary exception,
  and an acceptance check that greps the repo for "delve" or "leverage"
  and expects exactly one hit would misread this file's copy as drift
  rather than the stated, load-bearing exception it is.

### What changes in each file

- **`skills/voice-profile/references/ai-tells.md`** (new) — the canonical
  three-category list described above.
- **`skills/voice-profile/SKILL.md`** — fidelity procedure step 5 and the
  "Anti-leakage checklist" section point at the new file instead of
  restating it; the checklist section keeps its heading and gains the
  profile-override framing (em-dash example) at the pointer.
- **`skills/voice-rewrite/SKILL.md`** — frontmatter's "fix the tone" →
  "fix the tone so it sounds like me"; Diagnose step's tells bullet becomes
  a pointer at `voice-profile/references/ai-tells.md`.
- **`skills/voice-doc/SKILL.md`** — frontmatter's ambiguous "write a post"
  trigger resolved in favor of the existing "blog posts" noun; hand-off
  clause gains short social posts/tweets (→ voice-chat) and commit/PR
  prose (excluded, cites issue #8).
- **`skills/voice-chat/SKILL.md`** — frontmatter gains short social-media
  posts/replies to its claimed scope, matching voice-doc's corrected
  hand-off.
- **`skills/voice-harvest/SKILL.md`** — tool-access line becomes
  platform-neutral; "Relay prompt fallback" section keeps its trigger
  condition and post-processing steps but points at the new
  `references/relay-prompt.md` for the prompt text; LLM-content-filtering
  Pass 2 bullets become a pointer at `ai-tells.md`.
- **`skills/voice-harvest/references/relay-prompt.md`** (new) — the
  extracted, self-contained relay prompt (including its own necessarily
  self-contained tells-vocabulary examples and confidence-tier table copy).
- **`DESIGN.md`** — the Vocabulary table's AI-tells row updates from "no
  canonical form... four independent lists" to point at the new file as
  source of truth; the Anti-patterns section's open question about a 5th
  AI-tells list resolves to a stated anti-pattern (any skill wanting tells
  vocabulary points at `ai-tells.md`, never restates it).

## User journey

**Generate a draft, ambiguous "write a post" request (the corrected
routing edge).** User says "write a post about the launch for our team
Slack." Under the old frontmatters, "write a post" is voice-doc's own
trigger phrase — the request could land there, get the long-form register,
and come back Strunk-edited. Under this design: the request's actual shape
("for our team Slack") matches voice-chat's now-explicit claim on short
social posts, so it routes there — chat physics, no craft pass, per
voice-chat's existing "never Strunk-edited" rule. A genuine blog-post
request ("write a launch post for the blog") still routes to voice-doc
via the unambiguous "blog posts" noun, unaffected.

**Rewrite existing text, "fix the tone" request (the corrected trigger).**
User pastes a terse Slack reply and asks Claude to "fix the tone, it reads
too harsh." Under the old frontmatter, this is a literal, verbatim trigger
match for voice-rewrite. Under this design, the trigger reads "fix the
tone so it sounds like me" — still a match for the actual case (the user
wants their own voice back, not a generic softening), but the promise no
longer over-claims for a case where "fix the tone" means something
voice-rewrite was never built to do (a pure register/content judgment with
no voice-matching component) — that case now falls outside the literal
trigger match rather than inside a promise the skill's Purpose then
declines.

**A user asks for a commit message.** Under this design, no generator's
frontmatter claims this trigger. If asked directly, voice-doc's stated
exclusion is the answer a user would find: no generator here covers
dev-prose yet, tracked as issue #8. The persona gets an honest "not yet,"
not a draft quietly produced in a register that was never harvested for
this content type.

**Generate a draft, self-check for assistant-register leakage (CUJ #2,
any generator).** Unaffected in behavior — every generator still runs the
same fidelity self-check it does today. What changed is only that
"assistant-register leakage" now means the exact same, single, three-
category list regardless of which generator is delivering, instead of each
generator's own approximation of it. A trait like "seamlessly" or a
formulaic "Great question" opener, previously undetectable because it
wasn't on any of the four ad hoc lists, is now caught everywhere at once
because it's on the one list all of them read.

**First harvest, LLM-content filtering (CUJ #1).** Unaffected in behavior
— voice-harvest still runs its two-pass baseline-then-score filter exactly
as today. The Pass 2 exclusion signals it screens against are now the same
named list the generators self-check against, closing the gap issue #7
named directly ("harvest's contamination detector and the generators'
self-check should be the same detector").

**Relay prompt fallback, chat-history tools unavailable (any platform).**
Unaffected in behavior — the user still gets the same prompt to run on a
Claude surface with chat-history access, and it still pastes back into the
same Synthesis step. What changed is only where the prompt's text lives in
the repository (its own reference file instead of inline in `SKILL.md`)
and that the skill's own tool-access language no longer names a
Claude-Code-specific tool.

## Out of scope

- **The notes-vs-draft boundary between voice-doc and voice-rewrite**
  (issue #7 item 2). Not named in this story's acceptance criteria — a
  separate routing-edge question (already-prose-meant-to-survive vs.
  bullets-to-expand) that doesn't touch the AI-tells vocabulary or the two
  edges this story does fix. Left for a follow-up.
- **Cover letters, GitHub/forum comments, LinkedIn messages** (issue #7
  item 4's other unclaimed-territory examples, alongside commit/PR prose).
  Only commit/PR prose is named in this story's acceptance criteria; the
  others remain unaddressed by this epic's committed scope. Left for a
  follow-up rather than silently absorbed into any generator's claimed
  territory the way commit/PR prose is explicitly not.
- **voice-doc's "depends on no other skill" claim** and **its "deliver as
  markdown by default" claim on claude.ai chat** (issue #7's "Minor"
  section). Neither is named in this story's acceptance criteria; both are
  narrow wording corrections independent of routing or tells vocabulary.
  Left for a follow-up.
- **Issue #8 itself** (git-history harvest source, `dev.md` register). An
  out-of-band, unapproved proposal, not committed epic scope. This story
  only records that commit/PR prose is unclaimed pending it — it does not
  build any part of it, and does not assign commit/PR prose to an existing
  generator as an interim shortcut.
- **The evidence/confidence rubric** (issue #6, `evidence-standards`,
  already landed) **and the fidelity-procedure/path-resolution dedup**
  (issue #5, `fidelity-consistency` and `profile-durability`, already
  landed). This design builds on both without reopening either.
- **`voice-card-export` (#10) and `voice-check` (#9)** — `voice-card-export`
  is already landed; `voice-check` depends on this story landing first (it
  consumes `ai-tells.md` rather than re-deriving its own rubric) and is out
  of scope for this story to build.

## Alternatives considered

- **Leave the tells lists inline and only hand-sync their wording across
  files.** This would satisfy "the lists agree" without the structural
  fix. Rejected for the same reason `fidelity-consistency` rejected the
  equivalent shortcut for the fidelity procedure: hand-syncing is exactly
  the discipline that already failed once (DESIGN.md documents the four
  lists diverging despite three of them sharing "delve/leverage/
  streamline" as a common origin) and has no mechanism stopping the next
  edit to any one of them from drifting again. A single sourced file that
  the others point to is what makes the fix durable rather than a
  one-time resync.
- **Fold the tells vocabulary into `_format.md` instead of a new
  `ai-tells.md`.** `_format.md` already defines the per-register file
  contract (Traits/Exemplars/Anti-patterns/Strunk exemptions/Coverage) and
  is read by voice-harvest and the generators already. Rejected: the tells
  list isn't part of the per-register *data* contract — it's a shared,
  register-agnostic *detector* read the same way regardless of which
  register a generator is drafting in, and `_format.md`'s section headings
  are explicitly load-bearing ("Keep the section headings stable — the
  generators key off them"); adding an unrelated concept risks that
  stability for no benefit the acceptance criteria ask for, which
  literally names the new file's path as `voice-profile/references/
  ai-tells.md`.
- **Assign commit/PR prose to voice-doc outright**, since it's the
  closest-shaped generator and would resolve the "unclaimed territory"
  finding immediately. Rejected: voice-doc has no harvested `dev.md`
  register to draft from — assigning it ownership without the data issue
  #8 proposes to add would produce confidently-wrong drafts in a register
  nobody has actually harvested, the opposite of this suite's founding bet
  that harvested-and-quantified beats generic. Naming the gap is more
  honest than papering over it with the nearest-fit generator.
- **Route "write a post" ambiguity by asking the user every time**
  instead of splitting it at the frontmatter/trigger level. This would
  work but reintroduces a clarifying question on the suite's single
  highest-frequency-sounding trigger phrase, for a case ("for the blog" vs.
  "for Slack") that's almost always disambiguated by context already
  present in the request. Fixing the two frontmatters' claimed scope once
  is simpler than asking on every occurrence.

## Open questions

1. **Whether voice-doc counts as one of "the 4 scattered inline lists"
   this story fixes, given it already holds no restated list to fix.**
   The acceptance criteria's count of 4 matches issue #7's own audit
   citations (`voice-profile`, `voice-doc`, `voice-rewrite`,
   `voice-harvest`) at the time of that audit. Since then,
   `fidelity-consistency` collapsed voice-doc's own fidelity-check
   restatement (including its tells list) into a bare pointer at
   `voice-profile`'s procedure, as a side effect of that story's own
   dedup — not this one's. This design reads voice-doc as already
   satisfying "becomes a pointer" (it holds no restated vocabulary today),
   and treats the literal consolidation work as three files
   (`voice-profile`, `voice-rewrite`, `voice-harvest`) converging on the
   new canonical file. Flagging in case the gate expects a fourth file
   edited specifically to close this count.
2. **Whether voice-email's short parenthetical example belongs in this
   consolidation.** `voice-email`'s fidelity-check step includes "no
   assistant-register leakage (no 'I hope this email finds you well', no
   reflexive bulleting, no over-formal closers)" — a short example, not a
   restated list, and not one of the 4 locations issue #7 named. It shares
   the same underlying vocabulary this design consolidates, so converting
   it to a pointer too would leave zero near-duplicated examples anywhere
   in the repo rather than one small holdout. Proposed here as an
   in-spirit but not literally-named inclusion; flagging for the gate to
   confirm rather than deciding unilaterally to expand the named scope.
3. **Exact wording of each pointer, the ai-tells.md category contents
   beyond the newly-identified tells issue #7 names, and where precisely
   within voice-doc's frontmatter the commit/PR exclusion reads best** are
   left to the build worker's judgment — the contract here is the
   structural shape (one canonical file; each consumer points, none
   restate; two routing edges corrected; one exclusion stated) rather than
   specific prose.
4. **Whether a machine-checkable guard (in the shape of this epic's
   existing `scripts/check-canonical-resolution-string.sh` and
   `scripts/check-fallback-sample-count.sh`) should verify no file outside
   `ai-tells.md` and the relay prompt's necessary exception restates the
   vocabulary.** Both precedent scripts exist because this epic has
   already seen hand-synced duplication drift once; the same risk applies
   here. Left to the build worker to decide as an implementation detail,
   not prescribed by this design.
