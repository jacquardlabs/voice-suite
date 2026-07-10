# Design: New voice-card export skill

Story slug `voice-card-export`, epic `audit-fixes`. Source: issue #10. This
design covers only this story's acceptance criteria — a new skill that
compiles the installed profile (read from `profile-durability`'s stable
path) into a ~300-word portable prompt block: top traits, 2 micro-exemplars,
never-words, register notes, one pointer line back to the suite. It does not
touch the fidelity-procedure duplication (issue #5), the evidence/confidence
rubric (issue #6), AI-tells consolidation (issue #7), or the voice-check
fidelity scorer (issue #9) — those are separate stories, and per the epic
goal this one is scheduled to ship only once its prerequisite,
`profile-durability`, had landed. It has: `skills/voice-profile/SKILL.md`
already carries the canonical resolution-order string and the durable
`~/.claude/voice-profile/` path this design reads from.

## Problem & persona

Primary persona (PRODUCT.md): "A Claude user (Claude Code CLI/Desktop/IDE,
or claude.ai web/Desktop) who writes routinely across registers — long-form
docs, email, and chat/Slack — and wants AI-assisted drafts that read as
theirs, not as Claude's." Their job-to-be-done: "a first draft that needs
little or no voice-editing, only content edits."

Today that job-to-be-done is solved only *inside* the seven Claude Skills.
The moment this persona drafts somewhere else — ChatGPT custom
instructions, a Cursor `.cursor/rules` file, Gemini-in-Gmail, or a
teammate's `CLAUDE.md` on a machine without this plugin installed — none of
their harvested voice travels with them. They're back to generic,
detectably-AI prose everywhere except inside this one suite, even though the
suite already did the expensive work (5–15 minutes of harvest, plus every
tune patch since, per PRODUCT.md's "Current known problems" #1) of
extracting exactly what "theirs" means. The profile is real and current; it
just doesn't leave the building.

PRODUCT.md's "Current known problems" #1 also names claude.ai's degraded
loop directly: "On claude.ai the write path doesn't exist at all —
voice-tune's core loop is a no-op there." Issue #10 frames this story as a
mitigation for exactly that population: "a compiled card pasted into project
instructions is a workable degraded mode there" — a claude.ai user who can't
run the full read-write tune loop can still *carry* their harvested voice
into whatever surface they draft on, read-only, no write-back required.

This design serves PRODUCT.md's lead principle, "Profile over everything" —
today that principle is scoped to "everything inside these seven skills."
This story extends its reach to "everything the user touches," at the cost
of some fidelity (a static ~300-word block can't run the fidelity procedure
or a craft pass) in exchange for reaching surfaces the suite otherwise never
does.

## Proposed design

**A new, read-only, eighth skill, `voice-card`.** It reads the already-
harvested profile and compiles it down to a single self-contained prompt
block sized for pasting into another AI surface's system-prompt-equivalent
(ChatGPT custom instructions, Cursor rules, Gemini-in-Gmail, a `CLAUDE.md`
snippet). It writes nothing — no new consent surface, no new connector, no
mining. This keeps it aligned with "Consent-per-source, read-only mining"
(trivially — it does no mining at all) and "Draft-only, never send" (the
card is presented as a copyable block in the response, the same way
voice-doc/email/chat present a draft; the user pastes it wherever they
choose — the skill never posts or uploads it anywhere itself).

**Naming.** `voice-card`, not `voice-card-export` and not issue #10's own
suggested `/voice-export` — matching the one-word convention every sibling
skill uses (`voice-doc`, `voice-email`, `voice-chat`, `voice-rewrite`,
`voice-harvest`, `voice-tune`, `voice-profile`; DESIGN.md's surface table
lists these as literal slash-command entry points, e.g. `/voice-harvest`).
`voice-export` names the action but breaks the family's noun-after-`voice-`
pattern; `voice-card` names the artifact issue #10 itself calls "a
self-contained 'voice card'" and reads as a sibling of `voice-profile`, not
an outlier. `voice-card-export` remains the story/issue name; the skill
itself is invoked as `/voice-card` or by natural-language trigger ("export
my voice," "give me a portable version of my voice profile," "make a voice
card for ChatGPT").

**Resolving the profile.** `voice-card` quotes the canonical
resolution-order string byte-identical — the same block already carried by
`voice-profile`, `voice-doc`, `voice-email`, `voice-chat`, `voice-rewrite`,
`voice-harvest`, and `voice-tune` (7 files today, per
`scripts/check-canonical-resolution-string.sh`). `voice-card` becomes the
8th consumer of that exact text; the check script's `FILES` array must grow
to include `skills/voice-card/SKILL.md` so drift is still caught. This is
the epic pre-mortem's own warning (item 2: "every downstream story that
touches profile loading... must quote that exact committed text, not
paraphrase it" — voice-card-export named explicitly; item 6: the risk of
copying "the pre-fix pattern from an existing generator" instead of the
post-fix stable path). Reading the resolved directory means: `global.md`
plus all three register files (`longform.md`, `email.md`, `chat.md`) — the
card is meant to travel to any surface the user drafts on, so it can't
assume only one register matters.

**voice-card is not one of the four fidelity-procedure generators.** It
does not run the shared 6-step loop in `voice-profile/SKILL.md` ("pick the
register," "prime on exemplars," "draft voice-first," craft pass, fidelity
self-check, disclose low confidence) — that loop governs *drafting new
prose* for a request. Compiling a card instead selects, condenses, and
budgets existing profile fields into one artifact — picking "top" traits
and trimming exemplars to "micro" length is still editorial synthesis, just
not the drafting loop's synthesis, so it earns its own compile-and-budget
procedure below rather than a seventh generator-loop invocation. It does
reuse one specific idea from that loop — "disclose low confidence" —
because the same honesty concern applies: presenting a thin, low-confidence
profile as an authoritative export is exactly the "seemingly-authoritative"
risk PRODUCT.md's problem #3 already names for harvested confidence
generally.

**Compile procedure:**

1. **Resolve and gate.** Resolve the profile directory per the canonical
   string. If every file at the resolved location is still the empty
   shipped template (the string's own step 3 condition), refuse to compile
   a card and instead point the user to voice-harvest — the existing,
   already-worded fallback, not new copy.
2. **Check confidence.** Read each file's `## Coverage` block (already part
   of the shipped `_format.md` contract — sample count, confidence). If
   global and every register show low or no coverage, compile the card
   anyway but prepend one disclosure line: "Low-confidence profile — expect
   drift; refresh with voice-harvest." This mirrors the existing fidelity
   procedure's step 6 without inheriting the rest of that loop.
3. **Extract top traits from `global.md`.** Six fields, terse form:
   signature lexicon, hedging baseline, contractions, sentence-rhythm
   baseline, punctuation tics, capitalization habits. `global.md`'s
   "Drift note" (pre-AI vs. current voice) is harvest-internal bookkeeping,
   not portable guidance for a receiving LLM — excluded.
4. **Extract never-words.** Merge `global.md`'s "Lexicon — never-words"
   with any register-level never-words called out in each register file's
   own Traits/Lexicon line, deduped into one list. This is deliberately
   narrower than a register's full `## Anti-patterns` section (structural
   tells like "never opens with a greeting") — the acceptance criteria
   names "never-words" specifically; anti-patterns beyond a phrase or two
   folded into register notes (below) are the first thing trimmed if the
   card runs over budget.
5. **Pick 2 micro-exemplars.** Source them from whichever register file
   has the highest sample count / confidence in its `## Coverage` block —
   the most authentic, best-supported material available, rather than one
   exemplar per register (which the word budget can't afford at any
   register's normal exemplar length). Trim each to a single clipped
   sentence or fragment, verbatim, never invented.
6. **Write register notes.** One line per register (longform / email /
   chat), condensed from that file's Traits (formatting/structural habits,
   sentence length) — e.g. "Email: opens 'Hi X,', no exclamation points,
   signs off 'Best, B'. Chat: no greetings, fragments fine, emoji sparing
   (👍 😅). Longform: headers over bullets, mean 14-word sentences." A
   register with zero coverage is omitted rather than padded.
7. **Append the pointer line.** One fixed line: "— Compiled by Voice Suite
   (github.com/jacquardlabs/voice-suite). Refresh with voice-harvest;
   sharpen with voice-tune." This is the "every export is distribution"
   mechanic issue #10 names as the whole point of a pointer line existing.
8. **Budget check.** Target ~300 words; approximate allocation — pointer
   line ~15, top traits ~120, 2 micro-exemplars ~80, never-words ~40,
   register notes ~45. If the assembled draft runs long, trim in this
   order: register notes first, then least-distinctive traits, then
   shorten (never remove) exemplar text. Never drop the pointer line or the
   never-words list — those are the two things a receiving, non-Voice-Suite
   LLM will otherwise silently violate with no fidelity procedure of its
   own to catch it.

**Delivery.** The compiled card is presented as a single plain-text block in
the chat response, sized to paste whole into another surface's
system-prompt-equivalent. `voice-card` does not write it to disk and does
not call any external API — no ChatGPT/Cursor/Gemini connector exists or is
added by this story.

**Mechanical footprint (not this doc's design content, noted so it isn't
missed at build time):** README.md's "Seven Claude Skills" framing, its
7-skill table, and its "7 total" ZIP count for the claude.ai install path
all become stale the moment an 8th skill ships; the build worker updates
them the same way `profile-durability` updated README's per-platform data
paths.

## User journey

voice-card doesn't perform CUJ #2 ("Generate a draft") itself — it produces
a portable artifact that lets a surface *outside* Claude approximate CUJ
#2's outcome ("a first draft that needs little or no voice-editing") on its
own, without this suite's fidelity procedure or craft pass running there.
It changes none of the three existing CUJs: it runs only after CUJ #1
("First harvest") has already populated a profile, reads that profile
exactly like the four generators do, and mutates nothing — CUJ #1, #2, and
#3 ("Tune from an edit") are unaffected on every step. See Open Questions
for whether this warrants a fourth, separately-named CUJ in PRODUCT.md.

**Claude Code.** User has already harvested (CUJ #1 complete;
`~/.claude/voice-profile/` populated). User says "give me a portable
version of my voice" or "make me a voice card for ChatGPT." `voice-card`
resolves the profile (canonical string, step 1 — the durable Claude Code
path), runs the compile procedure above, and returns the ~300-word block
with its pointer line. User copies it into ChatGPT's custom instructions.
The next time they draft there, that surface's output leans toward their
signature lexicon, hedging level, and never-words — degraded relative to
the full fidelity procedure (no live exemplar-priming, no craft pass, no
per-draft self-check), but no longer generic. Re-running voice-card later
(after more harvesting or tuning) simply recompiles from the same resolved
directory — nothing to invalidate or version.

**claude.ai (web or Desktop app).** Canonical string step 1 doesn't resolve
(no such path exists there); step 2 resolves the installed `voice-profile`
skill's own `references/` folder instead — the same plain fall-through
every other consumer already relies on, so `voice-card` needs no
claude.ai-specific branch. The card compiles identically. This is the
degraded-but-workable path issue #10 calls out directly for the population
PRODUCT.md's problem #1 says can't run the full read-write tune loop:
they still get a portable artifact out of a read-only skill, no write-back
required.

## Out of scope

- **No new connectors or API pushes.** `voice-card` never calls a
  ChatGPT/Cursor/Gemini API on the user's behalf — issue #10's own "Fit"
  note says "no connectors"; pushing anywhere would also cross from
  draft-only into sending, which PRODUCT.md rules out for every generator.
- **No per-register cards.** One unified ~300-word card, not three. The
  acceptance criteria describes a single portable block with brief
  register notes, not a per-register export; three cards would also blow
  the word budget three times over for a marginal gain most external
  surfaces (a single system-prompt slot) can't use anyway.
- **No dependency on `fidelity-consistency`, `evidence-standards`, or
  `routing-tells-consolidation`.** Only `profile-durability` is a real
  prerequisite here — the acceptance criteria names its stable path
  explicitly, and `voice-card` only reads data those other three stories
  would each reshape in ways this story doesn't need: it doesn't run the
  fidelity procedure `fidelity-consistency` is unifying, doesn't consume a
  confidence rubric beyond the `## Coverage` fields already shipped, and
  doesn't score against the AI-tells list `routing-tells-consolidation`
  is consolidating (that dependency belongs to `voice-check` per issue #9's
  own text and the epic pre-mortem's item 7 — not to this story).
- **No file write, no card versioning/history.** The card is delivered in
  the chat response only; no `history/` snapshot ledger, no saved-cards
  directory. Consistent with every existing generator, which also never
  writes to disk on the user's behalf.
- **No automated word-count enforcement.** This is a prompt-only repo with
  no test framework (epic pre-mortem item 5); the ~300-word target and trim
  order above are self-check instructions inside the skill, the same shape
  as the existing fidelity procedure's step 6 — not a script this story
  adds.
- **No Strunk/craft-layer content in the card.** The craft pass and
  Strunk-exemption list are Voice Suite-internal drafting machinery; a
  receiving LLM on another surface doesn't run that algorithm, so including
  it would spend word budget on guidance nothing downstream can act on.

## Alternatives considered

- **Skip the micro-exemplars; ship traits and never-words only.** Rejected:
  `voice-profile/SKILL.md` already establishes that exemplars, not trait
  descriptions, "do the real work" ("Prime on exemplars, not descriptions"
  — the fidelity procedure's own step 2). A surface with no fidelity
  procedure at all needs concrete examples *more*, not less, than Claude
  does; dropping them would make the card weaker at the one job it exists
  to do.
- **Export one card per register instead of one unified card.** Rejected:
  contradicts the acceptance criteria's singular "~300-word portable prompt
  block," and most target surfaces (ChatGPT custom instructions, a single
  Cursor rules file, one `CLAUDE.md` snippet) have one slot to fill, not
  three — a per-register split would need the user to pick and merge
  manually, which is more work than the status quo of no card at all.
- **Push the card directly to other platforms via API/connector.**
  Rejected: no such connector exists in this repo for any external AI
  surface, and building one is a materially bigger, riskier addition (new
  auth, new consent surface, new failure modes) than a "small addition" the
  epic goal describes — also crosses the draft-only line PRODUCT.md draws
  for every existing skill.
- **Build a shared "profile compiler" module now, anticipating
  `voice-check`'s (issue #9) eventual need to also read the profile.**
  Rejected as premature: `voice-check` is not yet scheduled, its actual read
  shape is unknown (per its own issue text it reads `ai-tells.md`, not the
  register files this story reads), and speculative shared infrastructure
  for a hypothetical second consumer violates "prefer reuse over creation"
  in the direction that matters — reuse what already exists (the canonical
  resolution string), don't invent abstractions for reuse that isn't real
  yet.

## Open questions

1. **Should PRODUCT.md gain a fourth named critical user journey?** Today's
   three CUJs (harvest, generate, tune) don't name "export a portable
   card" as its own journey; this design frames it instead as riding on top
   of CUJ #1 and approximating CUJ #2's outcome elsewhere, rather than
   inventing a fourth entry unilaterally. Left for the gate to decide
   whether PRODUCT.md should be updated alongside this story or in a
   follow-up.
2. **Exemplar sourcing when multiple registers are equally well-covered.**
   Step 5 of the compile procedure picks the single highest-confidence
   register when there's a clear winner; the tie-breaking rule for two
   registers with comparable coverage (round-robin one exemplar each vs.
   picking the register the user's request implies) is left to the build
   worker's judgment, bounded by "verbatim, never invented" either way.
3. **How much of a register's `## Anti-patterns` beyond the merged
   never-words list, if any, is worth squeezing into register notes when a
   particular profile has budget to spare.** The trim-order rule (register
   notes first, traits second, exemplar length last) already bounds the
   downside; the upside case (a very thin, low-word-count profile with
   room to say more) is a judgment call for the build worker rather than a
   fixed rule this design commits to.
