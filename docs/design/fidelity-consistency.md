# Design: Dedup fidelity procedure, fix Strunk cross-skill mask

Story slug `fidelity-consistency`, epic `audit-fixes`. Source: issue #5
(remainder — the path-resolution half of #5 was already closed by the
`profile-durability` story). This design covers only this story's acceptance
criteria: making `voice-profile/SKILL.md`'s fidelity procedure the one
canonical copy the four generators point to instead of restate; converging
the four generators' disagreeing no-profile fallback sample counts; and
removing voice-email's cross-register Strunk-exemption borrowing along with
its dangling `strunk-rules.md` file dependency. It does not touch the
evidence/confidence rubric (#6) or AI-tells/routing consolidation (#7) —
separate stories in this epic.

## Problem & persona

Primary persona (PRODUCT.md): "A Claude user (Claude Code CLI/Desktop/IDE, or
claude.ai web/Desktop) who writes routinely across registers — long-form
docs, email, and chat/Slack — and wants AI-assisted drafts that read as
theirs, not as Claude's." Their job-to-be-done: get "a first draft that needs
little or no voice-editing, only content edits." That draft has to behave the
*same way* regardless of which of the four generators produced it — the
persona doesn't experience voice-doc, voice-email, voice-chat, and
voice-rewrite as separate products, they experience "the suite."

PRODUCT.md's "Current known problems" names this story's territory directly
(#2 of 4, second-highest-impact): "Profile path resolution and the fidelity
procedure are inconsistently duplicated — one generator hardcodes a
claude.ai-only path; the other three improvise resolution differently; the
'shared' 6-step fidelity loop is restated in all four generators with
disagreeing fallback sample counts; one generator has a dangling cross-skill
file dependency." The path-resolution half is already fixed. What's left:

1. **The fidelity procedure is restated, not shared, in five places.**
   `voice-profile/SKILL.md` states a 6-step "shared" procedure and calls
   itself "the authoritative copy" for profile *resolution* — but for the
   *drafting* procedure, it's one parallel restatement among five: itself
   plus voice-doc, voice-email, voice-chat, and voice-rewrite each write out
   their own version of "prime on exemplars → draft voice-first → craft pass
   → fidelity self-check → disclose low confidence" in their own words. Five
   copies of the same six steps is exactly the shape that produced the next
   problem.
2. **The five restatements disagree on the ad-hoc fallback sample count.**
   voice-doc asks for "2–4 samples," voice-email for "2–3 pasted real
   emails," voice-rewrite for "2–4 pasted samples," and voice-chat states no
   number at all ("a few," "a couple of examples"). A user who triggers two
   generators back to back in the same no-profile session gets two different
   answers to "how many samples do you need," for no reason grounded in the
   registers actually differing.
3. **voice-email's restatement invented a craft pass the canonical procedure
   never authorized, and reached into a sibling skill's file to run it.**
   The canonical procedure's craft-pass step reads: "For long-form and
   doc-scale rewrites, edit against the bundled craft rules... Chat register
   skips the craft pass entirely" — it never mentions email, in either
   direction. voice-email's own Step 5 nonetheless runs a craft pass "for
   long, external, formal email," reading `voice-doc/references/strunk-rules.md`
   ("if present" — a hedge that concedes the dependency is fragile) and
   "honoring the longform Strunk-exemption list." That list is emitted by
   voice-harvest specifically from long-form samples' *deliberate* rule
   violations (`_format.md`: "Strunk exemptions (longform.md only)... email.md
   and chat.md omit this section"). Applying it to an email draft borrows one
   register's craft-layer exceptions for a different register's voice — the
   long-form user might deliberately fragment sentences for rhythm; that
   doesn't mean their formal-email voice does the same, and if the resolved
   `~/.claude/voice-profile/` doesn't happen to have `voice-doc` installed
   alongside it, the read silently no-ops.
4. **Meanwhile, the harvested signal that content actually belongs to is
   unreadable.** voice-harvest's own bucketing rule files "longform — docs,
   long emails, posts" (its Synthesis step) — a user's long, formal
   correspondence is filed into `longform.md`, not `email.md`. voice-email's
   workflow only ever reads `global.md` + `email.md`. So the exact
   correspondence that should anchor "how do I write when I'm being formal"
   sits in a file voice-email never opens. The one thing voice-email
   currently *does* reach into `longform.md` for — the Strunk-exemption list
   — is the one thing it shouldn't; the exemplars and traits, which it
   should read, it doesn't.

These four are one connected failure, not four unrelated ones: because the
procedure was restated instead of shared, voice-email's restatement could
drift from the canonical text without anything flagging the divergence, and
the drift it picked up was exactly backwards — borrowing the wrong data
(craft-layer exemptions) while ignoring the right data (voice-layer
exemplars) sitting in the same file.

## Proposed design

### 1. One canonical fidelity procedure; generators point to it

`voice-profile/SKILL.md`'s existing "The fidelity procedure (shared)" section
becomes the one full-text copy. It gains an explicit opening line making the
pointer relationship a stated fact rather than an assumption: every
generator's drafting workflow follows these six steps; a generator's own
`SKILL.md` states only where it *deviates* (which register file, whether the
craft-pass step applies and how), never the steps themselves. This mirrors
the precedent already established for profile resolution: consumers point at
one location (`voice-profile`) rather than re-deriving the same logic
locally — the difference is that "resolving the profile" has to be
duplicated byte-identical because a skill needs the text in hand *before* it
can read anything else, whereas the drafting procedure is read *after* the
profile directory is already resolved, so a plain pointer ("follow
voice-profile's fidelity procedure, steps 2–6") is reachable the same way
voice-doc already reaches `references/strunk-rules.md` or the resolved
`longform.md` — no new mechanism, just fewer words at the point of use.

Each generator's `SKILL.md` keeps: its own Step 1 (load its register file;
what it does with no profile installed) and whichever content is genuinely
register-specific (voice-doc's craft-layer framing, voice-chat's "no craft
pass, ever," voice-rewrite's scale detection). It loses: the restated
prime/draft/craft-generic/fidelity-check/disclose language that is
today near-identical prose repeated four times.

### 2. Converge the fallback sample count to one number, stated once

The canonical procedure gains the explicit number: **2–4 samples of the
user's own writing in the relevant register**, stated once, in the canonical
copy's step 1. This is the number two of the four generators (voice-doc,
voice-rewrite) already use, so it changes zero drafting behavior for those
two. voice-email's restatement ("2–3") and voice-chat's (no number)
converge to point at the same canonical figure instead of stating their own
— each keeps only the register-flavor of its ask (voice-doc: "docs or long
emails they wrote"; voice-email: "real emails they wrote"; voice-chat: "a
few of their real messages, or examples of how they text"; voice-rewrite:
"pasted samples of the user's real writing"), not a competing count.

### 3. voice-email conforms to the canonical craft-pass step instead of
   deviating from it

This is a correction, not a new carve-out: the canonical procedure's
craft-pass step already excludes email by omission ("long-form and doc-scale
rewrites... chat register skips it entirely" — email in neither clause).
voice-email's Step 5 is the outlier. Fixing it means voice-email's craft-pass
language is deleted, not replaced:

- No craft pass for email, at any formality or length. This removes the read
  of `voice-doc/references/strunk-rules.md` entirely — the dependency is
  "resolved" by no longer existing, not by finding it a more reliable path.
- No borrowing of `longform.md`'s Strunk-exemption list. That list stays
  exactly what `_format.md` already specifies it is: longform-only craft-
  layer metadata, read by voice-doc and voice-rewrite alone.

### 4. Make the harvested signal voice-email was missing actually readable

Separately from the craft-pass removal above: when voice-email is drafting
an external/first-contact (formal-register) email, it also reads
`longform.md`'s **Traits and Exemplars** — never its Strunk-exemption
list — as supplementary voice signal for the formal end of the user's email
range, on the reasoning that voice-harvest's own bucketing files a user's
long, formal correspondence there. This directly satisfies "long formal
emails harvested into longform.md are readable by voice-email," using
exactly the same voice-layer/craft-layer separation the rest of the suite
already relies on (README: "Voice — wins... Craft — fills silence" are
different layers; this only ever touches the first).

**Known limitation, stated rather than hidden:** `longform.md` is not
email-only — voice-harvest's Synthesis step buckets "docs, long emails,
posts" together, so an exemplar pulled from there could just as easily be a
blog post as a formal email. Reading it can prime voice-email toward the
user's doc-register rhythm, not their email-register-but-formal rhythm, and
there is no reliable way to tell those apart from `longform.md`'s contents
alone. The mitigation this design adopts: treat this as a supplement, not a
replacement — `email.md`'s own exemplars are read first and always; the
`longform.md` read only fires for the external/formal sub-register, and the
fidelity procedure's existing "disclose low confidence" step is the
disclosure surface — voice-email says, at delivery, when a draft leaned on
this supplemental source, the same way it already discloses when `email.md`
itself is thin. No new confidence machinery is introduced (that's the
`evidence-standards` story's territory); this reuses the disclosure step
that already exists.

### What changes in each file

- **`voice-profile/SKILL.md`** — "The fidelity procedure (shared)" gains an
  opening sentence establishing it as the one full copy generators point to,
  and states the canonical "2–4 samples" fallback count in step 1. No other
  step's substance changes (it already correctly excludes email from the
  craft-pass step).
- **`voice-doc/SKILL.md`** — Workflow steps that restate priming, drafting,
  craft-pass mechanics, and the fidelity checklist collapse to a pointer at
  the canonical procedure; the craft-layer explanation (Strunk rule ranges,
  precedence) and the ad-hoc fallback's register flavor stay, with the
  fallback's specific number removed in favor of the pointer.
- **`voice-email/SKILL.md`** — Same collapse to a pointer for the shared
  steps. Step 5 (craft pass) is deleted outright rather than reworded. Step 1
  (load the register) gains the conditional supplemental read of
  `longform.md`'s Traits/Exemplars for the external/formal sub-register,
  with the disclosure note described above.
- **`voice-chat/SKILL.md`** — Same collapse to a pointer. Its one
  register-specific fact — chat never gets a craft pass — stays stated
  explicitly (worth keeping even though the canonical text also says it, since
  it's the most safety-critical exclusion in the suite: "Strunk on a Slack
  message is a category error").
- **`voice-rewrite/SKILL.md`** — Same collapse to a pointer for the
  shared steps; scale detection (chat-scale / email-scale / doc-scale) and
  its existing craft-pass gating are left as-is (see Open Questions — this
  skill has a sibling instance of the same mask pattern that this story's
  acceptance criteria don't name).
- **`README.md`** — the "Voice — wins, craft — fills silence" section's line
  stating email gets a craft pass "only for long, external, formal mail" is
  corrected to match: email never gets a craft pass; only long-form drafting
  and doc-scale rewrites do. The two `strunk-rules.md` bundle locations
  (voice-doc, voice-rewrite) are already accurately documented and are
  unchanged — no third location is being added.

## User journey

**Generate a draft, long-form (CUJ #2), unaffected register.** User asks for
a memo. voice-doc resolves the profile, follows the (now pointer-shaped)
fidelity procedure exactly as it does today: primes on `longform.md`
exemplars, drafts voice-first, runs the craft pass honoring the longform
Strunk-exemption list, self-checks, discloses if thin. Nothing about the
drafting behavior changes — only the words on the page describing it got
shorter, because they now point at one shared copy instead of repeating it.

**Generate a draft, a short, casual work email.** User asks for a quick
internal reply. voice-email loads `global.md` + `email.md`, drafts
voice-first from the internal sub-register, runs the fidelity check. No
craft pass — same as today, since short/internal mail already skipped it.
Unaffected.

**Generate a draft, a long, formal, external email — the corrected path.**
User asks for a first-contact email to a new client. Under the old design:
voice-email pulls the longform Strunk-exemption list and, if voice-doc
happens to be resolvable alongside it, edits the draft against Strunk rules
using exemptions that were derived from the user's *long-form* writing, not
their email writing — and if their genuinely most-formal correspondence was
harvested into `longform.md` (per voice-harvest's own bucketing), none of it
was ever consulted for voice at all. Under this design: voice-email drafts
from `email.md`'s external/formal traits and exemplars as before, plus
(new) supplements with `longform.md`'s Traits and Exemplars for additional
formal-register signal — explicitly as voice material, never as a craft
pass. No Strunk editing happens. If the supplemental read was used, the
delivery note says so, the same way a thin `email.md` alone would already
prompt a disclosure. The persona's job-to-be-done — a draft close enough to
theirs that only content needs editing — is better served for exactly the
register (long, formal, external) PRODUCT.md's "Current known problems"
flagged as the one where this suite's fidelity procedure was least
consistent.

**First harvest, then first draft in a no-profile session (either
platform).** Unaffected by any of the above except one thing: whichever
generator the user tries first when no profile exists yet asks for the same
"2–4 samples" it would have asked for regardless of which generator they
picked first. Today, trying voice-doc then voice-email in the same
no-profile session produces two different fallback asks ("2–4" then "2–3")
for no reason a user could explain; after this change, it's the same ask
both times.

## Out of scope

- **voice-harvest's own register-bucketing algorithm.** This design does not
  change *where* voice-harvest files long, formal correspondence (still
  `longform.md`, per its existing "longform — docs, long emails, posts"
  rule). It makes that data *readable* by voice-email; it does not
  re-classify it into `email.md`, which would be a harvest-side behavior
  change with its own approval-gate and Coverage-metadata implications, not
  named in this story's acceptance criteria.
- **Extending the profile contract with an email-specific Strunk-exemption
  section.** Considered and rejected below (Alternatives). `_format.md`'s
  existing statement — exemptions are longform-only, "no craft pass runs on
  [email/chat] by default" — is left as the authoritative contract; this
  design brings voice-email into conformance with it rather than amending it.
- **voice-tune.** It patches the profile; it never restated the fidelity
  procedure or any sample count (its Workflow is its own five-step patch
  loop), so there is nothing here for it to converge to. Its one
  Strunk-adjacent line ("For long-form, add a Strunk exemption...") already
  correctly scopes exemptions to long-form only and needs no change.
- **Quantified evidence/confidence rubric for harvested traits** (issue #6,
  the `evidence-standards` story) and **AI-tells vocabulary consolidation /
  routing edges** (issue #7) — separate stories in this epic. Where this
  design needs to talk about "thin" coverage or disclosure, it reuses the
  fidelity procedure's existing qualitative step rather than inventing any
  numeric threshold.
- **voice-rewrite's parallel craft-pass gating for email-scale content.**
  Flagged, not fixed here — see Open Questions.
- **`voice-card-export` (#10) and the `voice-check` fidelity scorer (#9)** —
  deferred by the epic goal until their prerequisites, including this story,
  land.

## Alternatives considered

- **Give `email.md` its own Strunk-exemption section instead of removing
  voice-email's craft pass.** This would let voice-email keep some form of
  craft pass, sourced from email-specific exemptions rather than borrowed
  longform ones. Rejected: it requires extending `_format.md`'s contract and
  teaching voice-harvest to score email samples against the craft rules
  separately from longform ones — a larger, invasive change to the shared
  data contract for a benefit ("email drafts get light Strunk editing") that
  no acceptance criterion asks for and the existing contract explicitly
  argues against ("no craft pass runs on [email] by default"). Removing the
  craft pass is the simpler fix that also happens to align voice-email with
  a contract that already existed — "prefer the simplest approach first."
- **Leave each generator's fidelity procedure fully restated, and only fix
  the disagreeing numbers and the Strunk borrowing in place.** This would
  satisfy criteria 2–4 without touching criterion 1. Rejected: it leaves the
  exact structural cause of criterion 2 and 3's bugs in place — five
  independent copies of the same steps, free to drift again the next time
  any one of them is edited. The dedup is what makes the fix durable rather
  than a one-time patch.
- **Re-bucket long, formal emails into `email.md` at harvest time**, instead
  of teaching voice-email to also read `longform.md`. This is a more
  "correct"-feeling fix for criterion 4 (the data would live where it's
  consumed) but changes voice-harvest's classification logic and its
  Coverage/gap reporting for two register files at once, is unnamed in the
  acceptance criteria, and doesn't fully avoid the ambiguity anyway — a long,
  formal email and a short technical memo can look identical in isolated,
  scrubbed exemplar form. Reading across registers with a stated limitation
  is the smaller, more honest change.
- **Only supplement from `longform.md` when `email.md` is completely
  empty**, rather than whenever the sub-register is external/formal. This
  is a plausible narrower gate. Not adopted as the primary design because
  it would silently stop helping the moment `email.md` has *any* formal
  exemplar, even a single thin one — see Open Questions for whether the
  design-review gate prefers this narrower trigger.

## Open questions

1. **Interpretation of criterion 1's exact wording.** "voice-profile/SKILL.md
   fidelity procedure is a pointer to one canonical copy, not a 5th
   restatement" is read here as: `voice-profile/SKILL.md` *is* the one
   canonical full-text copy (it already calls itself "shared" and is the
   data skill responsible for cross-generator contracts); the four
   generators are the restatements that collapse to pointers. This matches
   PRODUCT.md's problem statement ("the 'shared' 6-step fidelity loop is
   restated in all four generators") and is the interpretation this design
   builds on throughout. Flagging in case the gate reads the criterion
   differently.
2. **voice-rewrite's own email-scale craft-pass gating is the same mask
   pattern, unnamed by this story's criteria.** voice-rewrite's Step 5 reads:
   "Craft pass — scale-gated. For doc-scale rewrites, run the craft pass...
   honoring the longform Strunk-exemption list... Email-scale: only if long
   and formal." That last clause authorizes exactly the cross-register
   borrowing this design removes from voice-email, and the canonical
   procedure (unchanged by this design) doesn't authorize it either. Left
   untouched here because none of the four stated acceptance criteria name
   voice-rewrite, and the worker contract's scope is the story's stated
   criteria. Recommended as a follow-up — either folded into this story if
   the gate wants full consistency now (the epic goal explicitly says "every
   generator behaves consistently"), or filed as its own small fix. Deferring
   the decision rather than silently expanding scope.
3. **The external/formal trigger for reading `longform.md` (design item 4)
   vs. the narrower "only when `email.md` is empty for that sub-register"
   alternative.** Both satisfy "readable by voice-email"; they differ in how
   often the supplemental read fires and how often a disclosure note
   appears. Leaning toward the broader trigger (stated in Proposed design)
   because it degrades gracefully — worst case is an extra, disclosed
   voice-layer read — but flagging for the gate to weigh in on, since it's a
   judgment call rather than something the acceptance criteria pin down.
4. **Exact prose for the collapsed per-generator pointers** (how much
   register-specific framing each generator keeps vs. how much is left
   entirely to the canonical copy) is left to the build worker's judgment;
   the contract here is that the six steps' substance appears once, not the
   specific wording of each generator's remaining delta.
