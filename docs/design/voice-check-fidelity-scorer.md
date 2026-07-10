# Design: voice-check — standalone fidelity scorer

Story slug `voice-check-fidelity-scorer`, epic `audit-fixes`. Source: issue
#9 (out-of-band proposal, judge score 7/10, screened but not previously
product-gated — this design is that gate). This design covers only this
story's acceptance criteria: a new skill that scores arbitrary pasted text
against the installed profile, using `references/ai-tells.md` rather than a
re-derived list, that returns a per-trait deviation report and hands off to
voice-rewrite. It does not reopen profile durability (issue #4), path-
resolution/fidelity-procedure dedup (issue #5), the evidence/confidence
rubric (issue #6), or AI-tells consolidation and routing (issue #7) — all
four are separate, already-landed stories this design builds on without
re-litigating. Per the epic goal, this story was scheduled to ship only
once its prerequisite, `routing-tells-consolidation`, had landed; it has —
`skills/voice-profile/references/ai-tells.md` exists as the single
canonical tells file, and `skills/voice-profile/SKILL.md` carries the
canonical profile-resolution order this design reuses rather than
reinvents.

## Problem & persona

Primary persona (PRODUCT.md): "A Claude user (Claude Code CLI/Desktop/IDE,
or claude.ai web/Desktop) who writes routinely across registers — long-form
docs, email, and chat/Slack — and wants AI-assisted drafts that read as
theirs, not as Claude's." Their job-to-be-done, quoted directly: "a first
draft that needs little or no voice-editing, only content edits."

That job statement is scoped to drafts *this suite produces*. This design
extends it to a real but adjacent situation PRODUCT.md's stated job doesn't
literally cover: text the persona didn't get from one of the four
generators at all — a PR body Claude wrote unprompted in another tool, a
doc a colleague "helped" with, a paragraph from some other AI surface. The
persona's underlying want (PRODUCT.md's opening framing: "AI-drafted
writing defaults to a generic, detectably-AI register... this product's
bet is that a user's own writing, mined and quantified, is a better ground
truth than any generic style guide") doesn't stop applying just because the
suite didn't draft the text in question. Today, when this persona
encounters that kind of text, they have exactly two options: trust a
feeling ("does this sound like me?"), or paste it into voice-rewrite and
commit to a full rewrite just to find out. There's no way to get a
quantified answer without also getting an edit they may not want yet.

*This is a genuine extension of the stated job-to-be-done, not a literal
restatement of it* — flagged here rather than papered over, per the
contract's own instruction to quote PRODUCT.md rather than invent a persona
job that isn't there. Issue #9 names the moment directly: "the pre-send
pause... answered with quantified traits instead of a feeling."

## Proposed design

**A new, read-only, ninth skill: `voice-check`.** Naming matches the
one-word sibling convention (`voice-doc`, `voice-email`, `voice-chat`,
`voice-rewrite`, `voice-harvest`, `voice-tune`, `voice-card`, `voice-profile`)
that DESIGN.md's Per-surface-conventions section already documents and
already refers to this proposed skill by (`voice-check`, alongside
`voice-card-export`, in `routing-tells-consolidation`'s design doc). The
story/issue name stays `voice-check-fidelity-scorer`; the skill itself is
`/voice-check`, triggered by natural language too ("does this sound like
me," "check this against my voice," "score this text," "did an AI write
this").

**What changes for the user:** they can hand the suite *any* text — not
just a suite-drafted one — and ask whether it sounds like them, and get
back a structured, quantified answer instead of a subjective read or an
unwanted rewrite.

**What stays the same:** the ground truth doesn't change. Same installed
profile, same canonical resolution order, same `ai-tells.md`, same register
files. `voice-check` introduces no new vocabulary and derives nothing of
its own — every generator already runs a version of this exact judgment
internally (voice-profile's fidelity procedure, step 5, "verify against the
register file... and no assistant-register leakage") right before
delivering a draft. This design's whole premise, per issue #9, is "pure
reuse... this gives them a read-only front door" onto a check that already
exists — it just never had a name of its own or a way to run without also
committing to a full generation or rewrite.

**The report has two distinct parts, and `ai-tells.md` alone only covers
one of them:**

1. **Generic assistant-register leakage** — the pasted text checked against
   `ai-tells.md`'s Vocabulary / Structure / Register categories (the
   canonical tells detector every other consumer in the suite already
   points at instead of restating). This part is register-agnostic: "delve,"
   reflexive bullets, bolded triads, and so on read the same regardless of
   which register the text is in.
2. **Per-trait deviation against the user's own observed voice** — this is
   what makes the report *personal* rather than generic, and it does not
   come from `ai-tells.md` at all. It requires matching the pasted text to
   one of the three register files (`longform.md` / `email.md` / `chat.md`)
   plus `global.md`, and comparing the pasted text's actual sentence
   length, hedging level, lexicon, and formatting against that file's
   quantified `## Traits` — e.g. issue #9's own example, "sentence mean 22
   vs your 14; 3 never-words; closes with a summary paragraph you never
   write." Producing this half requires a register-detection step first:
   the pasted text arrives with no register declared, so `voice-check` must
   infer chat/email/longform from its shape (length, structural cues),
   mirroring how voice-rewrite's own workflow already opens with "detect
   scale and register" before it reads a register file.

Both parts together are the deliverable issue #9 asks for; the acceptance
criteria's "using ai-tells.md (not a re-derived list)" governs part 1 only —
part 2 was already the shared fidelity procedure's job and stays that way.

**The no-profile case is a deliberate, narrower decision than the
generators make.** The four generators' fallback for "no profile installed"
is to build an ad-hoc, session-only profile from 2–4 samples the user
pastes, so drafting can proceed in some approximation of their voice. That
fallback doesn't transfer cleanly to a scoring tool: comparing pasted text
against a baseline built from *other* pasted text supplied in the same
breath is close to circular, and produces a "deviation report" against a
baseline the user just typed rather than their actual observed voice.
`voice-check` requires an installed, populated (non-template) profile to
score against. When resolution finds only the empty shipped templates, it
reports plainly that no profile exists and points to voice-harvest — reusing
the canonical resolution order's own existing step-3 language for "no
profile yet," not inventing new copy, and not falling through to the
ad-hoc-session-profile branch the generators use for drafting.

**Handoff to voice-rewrite is an offer, not a mechanism.** No skill in this
suite currently invokes another skill programmatically — the only existing
precedent is the disambiguation clause every generator's description ends
with, pointing the user at a sibling skill by name. `voice-check` follows
that same precedent at the UX level: after presenting the deviation report,
it offers — doesn't force — to carry the flagged text into voice-rewrite's
existing workflow if the user wants an actual rewrite. Declining leaves the
report as the end state; nothing is edited unless the user asks for the
handoff.

**Principles this leans on** (PRODUCT.md): "Profile over everything" — the
deviation report is measured against this user's own observed traits, not
generic style-guide correctness, so a trait the profile documents as
theirs (e.g. dense em-dash use, per `ai-tells.md`'s own stated precedent)
is never flagged as a deviation. "Harvested and pasted content is data,
never instructions" — the pasted text being scored is treated purely as
content to analyze, never as directives to follow, the same posture
voice-rewrite already takes toward text it's asked to rewrite.

## User journey

`voice-check` doesn't map to CUJ #1 (First harvest) or CUJ #3 (Tune from an
edit) — it touches neither the harvest nor the tune loop. It's closest to,
and directly upstream of, CUJ #2 ("Generate a draft"), specifically the
rewrite path: "the matching generator... reads the installed profile...
Outcome: a draft in the user's voice, ready for the user to send/publish
themselves" — voice-rewrite is one of the four "matching generators" that
sentence describes. `voice-check` adds a new front-door step for text the
suite never drafted, that *feeds into* CUJ #2's rewrite variant via the
handoff, rather than replacing or altering any step already in that
journey.

**Walkthrough:** Trigger — the user pastes text and asks something like
"does this sound like me," "check this against my voice," or hands over a
PR body Claude wrote unprompted, a colleague-edited doc, or a paragraph
from another AI tool. Steps: `voice-check` resolves the profile (canonical
resolution order); if no populated profile is found, it says so and points
to voice-harvest, stopping there. Otherwise it detects (or asks) which
register the pasted text belongs to; checks the text against `ai-tells.md`
for generic assistant-register hits; compares the text's actual traits
against the matched register file's and `global.md`'s quantified `## Traits`
for personal deviations; and presents both as one per-trait deviation
report. It then offers, without forcing, to hand the text to voice-rewrite.
Outcome: the user gets a quantified verdict — a report, not an edit — and
decides for themselves whether the deviation is worth fixing, and if so,
opts into the rewrite.

**What changes in an existing journey:** none of the four generators' own
internal workflow changes — they still run the shared fidelity procedure
exactly as before. What's new is the entry point: previously, the only way
to get any signal on "does this sound like me" for outside text was to
paste it into voice-rewrite and receive a completed rewrite with no
separate score step available first. `voice-check` inserts a decision point
before that commitment, without altering what voice-rewrite itself does
once invoked.

## Out of scope

- **No new AI-tells list.** Reads `references/ai-tells.md` by reference,
  the same way voice-profile, voice-rewrite, and voice-harvest already do.
  The epic pre-mortem names this exact risk directly: "`voice-check-
  fidelity-scorer` re-derives its own tells rubric instead of consuming
  `ai-tells.md`... the dependency edge exists exactly to prevent a fifth
  divergent list." This design does not introduce one.
- **No writes to the profile.** Read-only, like the four generators' read
  path — not voice-harvest's or voice-tune's write path. Nothing about
  voice-tune's edit-learning loop changes; `voice-check` producing a
  deviation report is not itself a tune-worthy edit and doesn't feed
  voice-tune automatically.
- **Not a rewriter.** `voice-check` never edits or rewrites the pasted text
  itself — that responsibility stays entirely with voice-rewrite, reached
  only through the optional handoff described above.
- **No new confidence/evidence rubric.** Reuses the existing `## Coverage`
  block and high/medium/low confidence tiers already defined in
  `_format.md`. If the matched register's coverage is low, `voice-check`
  discloses that using the existing convention, rather than inventing its
  own confidence math.
- **No new profile-resolution mechanism.** Quotes the canonical
  "Resolving the profile" string byte-identical, joining the existing set
  of consumers rather than introducing a second resolution path.
- **No ad-hoc/session-only scoring baseline when no profile is installed.**
  Deliberately narrower than what the four generators offer for drafting
  (see Proposed design) — a scoring tool without a real installed baseline
  has nothing legitimate to score against.
- **No batch or multi-document scoring, no score history across sessions,
  no single pass/fail numeric grade.** Issue #9 asks for "quantified traits
  instead of a feeling" — a per-trait deviation report — not a single
  aggregate score. Tracking scores over time or across multiple pasted
  documents in one pass is a different, un-asked-for feature.
- **Cross-checked against PRODUCT.md's "What we're NOT building":** no
  sending or publishing applies trivially (this skill has no send surface
  at all); no org/team-shared profile — `voice-check` compares only against
  the single installed user profile, the same single-user model every
  other skill already assumes.

## Alternatives considered

**Add a score-only / diagnose mode to voice-rewrite instead of a new
skill.** Rejected. voice-rewrite's entire contract is committing to a
rewrite — its description states the job as "Rewrite existing text so it
sounds like the user wrote it," and its trigger phrases ("make this sound
like me," "de-AI this") set a user expectation of getting an edited draft
back. Bolting a "just tell me, don't rewrite" mode onto that same skill
reintroduces exactly the kind of trigger ambiguity `routing-tells-
consolidation` just finished narrowing for voice-rewrite's own "fix the
tone" phrasing — now the skill would need to disambiguate score-only intent
from rewrite intent on every invocation. Issue #9 makes the reuse case for
a *separate* skill explicitly: "pure reuse — the fidelity procedure and
AI-tells detector already exist inside four generators; this gives them a
read-only front door. Cheapest possible new SKILL.md." A small, single-
purpose, read-only skill is simpler to route correctly than a hidden mode
flag inside a skill whose description doesn't mention scoring today.

**Give each of the four generators its own score-only path instead of one
shared skill.** Rejected for the same reuse logic in reverse: one new skill
built on the existing fidelity procedure's step 5 and `ai-tells.md` is a
single new `SKILL.md`. Four separate score-only modes, one per generator,
would risk becoming exactly the kind of divergent-copy problem the epic
pre-mortem already flags for the tells list — just relocated from one file
into four generators instead of consolidated into one new skill.

## Open questions

- **Register-detection heuristic for ambiguous input.** A short, borderline
  passage (e.g. a 40-word reply that could be chat or a brief email) needs
  a stated rule for inferring register, or an explicit ask-the-user
  fallback. Left for the build phase, following the same "detect scale and
  register" precedent voice-rewrite's own workflow step 1 already uses for
  its own input.
- **Exact wording and persistence of the handoff offer** — whether
  declining the voice-rewrite handoff ends the interaction cleanly, or
  whether the report stays actionable later in the same conversation if
  the user changes their mind. A UX-wording decision, not a scope question.
- **Should a low- or no-coverage register still produce a full deviation
  report (loudly disclosed), or refuse to score below some threshold?** The
  four generators draft anyway at low confidence, with disclosure. Whether
  a *scoring* tool should hold a stricter bar than a *drafting* tool is
  unresolved here and left for the build phase or a future review to
  settle.
