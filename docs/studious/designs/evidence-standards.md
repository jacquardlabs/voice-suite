# Design: numeric confidence rubric + pending-observations ledger

Story: `evidence-standards` (epic `audit-fixes`, source: issue #6).

## Problem & persona

Primary persona (PRODUCT.md): "A Claude user … who writes routinely across
registers — long-form docs, email, and chat/Slack — and wants AI-assisted
drafts that read as theirs, not as Claude's." Their trust in a draft depends
on trusting what the profile claims about itself.

PRODUCT.md's own problem list names this story's target directly (problem 3,
"Current known problems"):

> No numeric evidence standards for harvested confidence — "high/medium/low"
> confidence has no rubric or minimum sample count; a handful of chat messages
> can produce a fully-populated, seemingly-authoritative Traits section.
> voice-tune's overfitting guard ("require a repeated pattern") is also
> unenforceable across sessions since tune has no memory (issue #6).

Two distinct failures share one root cause — the profile contract has no
notion of *evidence weight*, only a free-text label a harvester fills in by
feel:

1. **Confidence is asserted, not computed.** `_format.md`'s Coverage section
   asks for "high / medium / low, with a one-line basis" — there is no floor.
   Three messages and three hundred can both read "high" if the harvester
   feels confident. The persona has no way to tell, from the profile alone,
   whether a trait rests on real volume or a lucky handful of samples — and
   the fidelity procedure's own low-coverage disclosure step
   (`voice-profile/SKILL.md`, "Disclose low confidence") is only as honest as
   the label it reads.
2. **A repeated correction has no way to persist across sessions.** voice-tune
   already refuses to promote a one-off edit to a standing trait ("Require a
   pattern, not a one-off") — but that guard only sees the current
   conversation. An edit the user makes every Monday for a month never
   accumulates into "this is a pattern," because nothing records that it was
   seen before.

## Proposed design

Two additions to `voice-profile/references/_format.md` — the profile
contract voice-harvest emits, voice-tune patches, and every generator reads.
This story touches exactly two files: `_format.md` and
`voice-harvest/SKILL.md`. It does not touch `voice-tune/SKILL.md`, the
per-register template files, or any generator (see Out of scope).

### 1. Confidence becomes a computed tier, not an asserted label

The Coverage section's Confidence line changes from a free-text pick to a
lookup: sample count against a per-register threshold table, expressed and
disclosed together (e.g. "medium (22 messages)"), never as the tier alone.
Thresholds, adopted verbatim from issue #6 rather than re-derived:

| Register | High | Medium | Low |
|---|---|---|---|
| Chat | ≥100 messages | ≥30 messages | <30 messages |
| Email | ≥40 sent messages | ≥15 sent messages | <15 sent messages |
| Longform | ≥8 pieces | ≥3 pieces | <3 pieces |

Registers get different floors because they have different natural volumes —
chat messages are cheap and abundant, longform pieces are rare and
expensive. The per-register reference-file split already assumes this; a
single global threshold would misrepresent both ends.

Below medium (the low tier), two additional gates apply everywhere:

- Emit a given trait only where **at least 3 independent samples agree** on
  it. A trait resting on one or two samples at low coverage is a guess wearing
  a Traits-section costume.
- **Never emit a Strunk exemption.** A rule violation seen once or twice in a
  thin longform sample is indistinguishable from an error; exemptions require
  the volume to tell a deliberate pattern from a fluke.

`_format.md` is the canonical location for these numbers. voice-harvest's
Synthesis step states the same table and cites `_format.md` rather than
restating a rationale — one source of truth, one mirror, so a future editor
knows which copy to change. This is deliberate: the epic's other stories are
busy *removing* duplicated numbers (issue #5's fidelity-procedure copies,
issue #7's four AI-tells lists); this story must not add a third un-synced
copy anywhere convenience suggests one (see Alternatives).

The relay-prompt fallback template — the fenced block voice-harvest hands to
a user running the harvest from a Claude surface without chat-history
tools — carries its own embedded Coverage instructions ("Confidence: [high /
medium / low] — [one-line basis]"). This story updates that copy too, to the
same table. Rationale: the relay path produces the exact same Coverage data
that lands in the profile; leaving it vibes-based would let a
non-quantified confidence back into the profile through the one path that
routes around voice-harvest's own tool access, undoing the fix for whichever
users hit that fallback. Same file, same skill, not another story's
territory.

### 2. A quarantine buffer for unconfirmed observations

`_format.md` gains a sixth section, `## Pending observations`, appended after
`## Coverage`. It holds dated, one-line observations that look like a voice
pattern but haven't yet been seen enough times to trust:

- One line per observation: what was observed and when, with an occurrence
  count that increments on repeat sightings.
- **Generators ignore this section entirely.** It is write-side bookkeeping
  between successive harvest/tune-style passes, not draft-time signal — the
  fidelity procedure and every generation skill read Traits/Exemplars/
  Anti-patterns/Coverage only.
- **Promotion rule:** an observation seen a 2nd time is a real candidate; by
  the 3rd occurrence it must be promoted into Traits or Anti-patterns
  (whichever it describes) and removed from this list. An explicit user
  confirmation ("yes, I always do that") promotes immediately regardless of
  count. Absent that, two identically-worded sightings promote outright at
  occurrence 2; two sightings that agree in substance but not wording hold for
  a 3rd before promoting — mirroring the "when in doubt, ask" judgment
  voice-tune's workflow already uses for one-off vs. pattern.

This section is a **contract addition only** in this story — it defines the
shape and the rule; it does not wire a producer. See Out of scope.

### Build constraint: the five existing headings are load-bearing text, not just structure

`Traits` / `Exemplars` / `Anti-patterns` / `Strunk exemptions` / `Coverage`
must remain byte-identical as heading lines, in their existing relative
order — every generation skill keys off this exact heading text to parse the
file. This story changes the *body* of Coverage (adds the threshold table)
and *appends* a sixth heading after it; it does not rename, reorder, or
reword any of the five existing heading lines. The distinction matters
because Coverage's body necessarily changes (that's the whole point of
criterion 1) while the heading itself does not — "byte-identical" scopes to
the heading text and order, not to section contents that this story is
explicitly asked to change.

## User journey

**Journey 1 — First harvest** (PRODUCT.md). At the Synthesis step, the
harvester no longer picks a confidence word — it counts samples for the
register, looks up the tier from the table above, and reports it with the
count ("medium (22 messages)"). The user's exemplar-approval-gate experience
is unchanged; what changes is that the Coverage line they see afterward is
now falsifiable — they can count their own thirty-odd chat messages against
"medium (≥30)" and see the tier isn't asserted, it's a lookup.

**Journey 3 — Tune from an edit** (PRODUCT.md). This story does **not**
change tune's runtime behavior. It defines the container a future story would
use to make a cross-session pattern visible — today, and after this story
ships, an edit repeated on separate days is still invisible to tune the way
it is now, because nothing yet writes into `## Pending observations`. Flagged
explicitly in Open questions below; it is the one place this design doc's
scope stops short of the full problem issue #6 describes.

Journeys 2 (generate a draft) and the What-we're-NOT-building list are
unaffected — no generator's read path changes.

## Out of scope

- **Wiring voice-tune to actually write, read, or promote from `## Pending
  observations`.** The epic ledger's dependency graph gives this story no
  edge into `voice-tune/SKILL.md`, and its acceptance criteria name only
  `_format.md` and voice-harvest's synthesis step. Touching a third skill file
  not named in scope risks exactly the cross-story merge overlap the epic
  pre-mortem's item 1 warns about. The section ships as a defined, empty
  contract — inert until a follow-up story wires a producer.
- **Any change to profile storage location or path resolution** — issue #4 /
  story `profile-durability`'s territory.
- **The shared fidelity procedure, cross-skill Strunk masking, or generator
  read-path changes** — issue #5 remainder / story `fidelity-consistency`.
- **AI-tells consolidation, routing edges** — issue #7 / story
  `routing-tells-consolidation`.
- **voice-card-export, voice-check-fidelity-scorer** — issues #10 / #9,
  separate stories gated on other prerequisites.
- **Re-deriving the threshold numbers.** Issue #6 already proposes concrete
  per-register floors; this design adopts them verbatim rather than
  re-litigating what "enough" samples means.

## Alternatives considered

1. **A separate rubric reference file** (e.g.
   `references/confidence-rubric.md`), pointed to from both `_format.md` and
   voice-harvest. Rejected: it would require a *third* synced copy of the
   same numbers in an epic whose other stories are actively collapsing
   duplicated copies (issue #5's fidelity procedure, issue #7's AI-tells
   lists) into single sources. Two mirrored copies (contract + harvest,
   explicitly labeled canonical vs. mirror) is the minimum this story's own
   acceptance criteria require; a third location adds sync risk with no
   reader benefit.
2. **Wire voice-tune's full pending-observation loop in this same story**,
   since tune is the section's only plausible producer. Rejected for now:
   the epic ledger scopes this story to `_format.md` + voice-harvest (`deps:
   []`, criteria naming only those two), and voice-tune is under no
   dependency edge from this story. Expanding the file footprint beyond what
   was recorded risks the merge conflicts the epic pre-mortem calls out
   between stories that "touch the same handful of SKILL.md files." Shipping
   the contract now and wiring the producer as an explicit follow-up keeps
   each story's blast radius matched to what it was scoped and reviewed for.

## Open questions

1. **No story in the current epic ledger wires a producer into `## Pending
   observations`.** As designed, the section ships permanently empty unless
   `voice-tune/SKILL.md` is later updated to write into it — worth a decision
   from whoever owns the epic backlog on whether that's a follow-up issue to
   file now, or an accepted "ships inert, wired later" gap.
2. **Should the three shipped empty per-register templates** (`chat.md`,
   `email.md`, `longform.md` under `voice-profile/references/`) get the new
   `## Pending observations` placeholder heading now, so a fresh install's
   templates match the contract they claim to follow (each says "Format
   spec: see `_format.md`")? Not required by this story's acceptance
   criteria; deferred to the design reviewer's call rather than expanding
   scope unilaterally.
