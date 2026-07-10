# Register file format (the profile contract)

Every per-register reference file (`longform.md`, `email.md`, `chat.md`)
follows this structure. voice-harvest emits it; voice-tune patches it; the
generation skills read it — except `## Pending observations`, which is
write-side only (see below). Keep the section headings stable — the
generators key off them.

---

## `## Traits`

Quantified wherever possible. Vague traits produce vague drafts.

- **Sentence length:** mean and spread, e.g. "mean 14 words, range 4–31,
  high variance — mixes terse and sprawling."
- **Paragraph length:** typical sentences per paragraph.
- **Hedging level:** frequency + the actual hedge words used.
- **Formality:** where this register sits on the user's own scale.
- **Lexicon (this register):** signature words; never-words.
- **Punctuation tics:** em-dashes, semicolons, ellipses, parentheticals.
- **Formatting habits:** prose vs. headers vs. bullets; emoji; sign-offs/
  openers (especially for email and chat).
- **Structural habits:** how they open, how they close, how they transition.

## `## Exemplars`

3–8 verbatim passages the user actually wrote in this register. Scrubbed of
names, numbers, and identifiers. **User-approved** — the harvest exemplar gate
is what put them here. These do the real work at draft time, so choose ones
that span the register's range (a terse one, a careful one, a long one).

## `## Anti-patterns`

The never-does list: constructions, words, and formatting this user
demonstrably avoids. This is as load-bearing as the traits — it's how the
generators detect and strip assistant-register leakage.

## `## Strunk exemptions` (longform.md only)

Rule numbers from the craft layer that this user *deliberately* violates as
part of their voice, each with a one-line reason. The craft pass reads this
list and disables exactly these rules. Example:

- Rule 11 (positive form) — exempt: hedging is a load-bearing trait.
- Rule 14 (loose sentences) — exempt: conjunction-chained rhythm is signature.
- Rule 6 (sentence fragments) — exempt: fragments used deliberately for beats.

email.md and chat.md omit this section (no craft pass runs on them by
default).

## `## Coverage`

Honesty metadata the generators use to calibrate and disclose:

- **Sample count:** how many authentic samples fed this register.
- **Date range:** earliest–latest (flags pre-AI vs. current voice).
- **Confidence:** a computed tier, never an asserted label — look up the
  sample count against the register's threshold below and report tier
  *with* count together, e.g. "medium (45 messages)". The tier is a pure
  function of that count and nothing else moves it directly: a tune-derived
  correction patches the trait or anti-pattern it corrects, not this tier —
  the tier only changes when the register's underlying sample count does
  (e.g., a refresh harvest adding samples):

  | Register | High | Medium | Low |
  |---|---|---|---|
  | Chat | ≥100 messages | ≥30 messages | <30 messages |
  | Email | ≥40 sent messages | ≥15 sent messages | <15 sent messages |
  | Longform | ≥8 pieces | ≥3 pieces | <3 pieces |

  Below medium, two gates apply everywhere:
  - Emit a given trait only where at least 3 independent samples agree on
    it. A trait resting on one or two samples at low coverage is a guess
    wearing a Traits-section costume.
  - Never emit a Strunk exemption. A rule violation seen once or twice in a
    thin longform sample is indistinguishable from an error; exemptions
    require the volume to tell a deliberate pattern from a fluke.
- **Gaps:** what's thin (e.g., "no external-formal emails observed").

## `## Pending observations`

A quarantine buffer for unconfirmed patterns — dated, one-line candidates
that look like a voice trait but haven't been seen enough times to trust.

- One line per observation: what was observed, when, and an occurrence
  count that increments on repeat sightings.
- **Generators do not read this section.** It is write-side bookkeeping
  between successive harvest/tune-style passes, not draft-time signal. That
  holds today by construction, not by an enforced read-path exclusion: this
  section ships with no producer writing to it yet (see below) and no
  generation skill's read path has been updated to reference it. A future
  story that wires a producer into this section must also confirm the
  shared fidelity procedure keeps scoping its reads to Traits/Exemplars/
  Anti-patterns/Coverage rather than picking this section up incidentally.
- **Promotion rule:** a 2nd occurrence makes it a real candidate; a 3rd
  occurrence promotes it into Traits or Anti-patterns (whichever it
  describes) and removes it from this list. An explicit user confirmation
  ("yes, I always do that") promotes immediately regardless of count.
  Absent that, the wording comparison is between the observed instances
  themselves — the actual phrase or construction the user wrote each
  time — not between the logged one-line descriptions of them: two
  sightings where that underlying phrase repeats verbatim promote outright
  at occurrence 2; two sightings where the pattern is the same but the
  actual wording differs (as in the example below) hold for a 3rd
  occurrence before promoting.

---

### Minimal filled example (chat.md)

```
## Traits
- Sentence length: mean 7 words, often fragments. Rarely > 15.
- Hedging: low. Direct. "yeah", "nope", "do it".
- Formality: very low. Lowercase-default except names.
- Lexicon: "tbh", "lol", "wait —"; never-words: "regards", "kindly".
- Punctuation: em-dash for asides, trailing "..." for hesitation. No periods
  on single-line messages.
- Emoji: sparing, end-of-message only. 👍 and 😅 mostly.

## Exemplars
- "wait — did we ever ship the thing? thought that was blocked"
- "yeah do it, lgtm"
- "ugh ok give me 10 min, on a call 😅"

## Anti-patterns
- Never opens with a greeting ("Hi", "Hey there") on an active thread.
- Never uses full Title Case or formal sign-offs.
- Never writes multi-sentence paragraphs in chat.

## Coverage
- Sample count: 240 messages.
- Date range: 2024-01 to 2025-12.
- Confidence: high (240 messages) — large, recent, clean sample.
- Gaps: few work-channel (vs. DM) samples.

## Pending observations
- 2026-06-30: opens replies with a quick scene-setter — "quick note —",
  "quick thing —" (seen 2x, wording varies; holds for a 3rd occurrence
  before promoting, per the substance-not-wording branch of the rule
  above).
```
