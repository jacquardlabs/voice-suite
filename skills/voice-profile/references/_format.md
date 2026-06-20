# Register file format (the profile contract)

Every per-register reference file (`longform.md`, `email.md`, `chat.md`)
follows this structure. voice-harvest emits it; voice-tune patches it; the
generation skills read it. Keep the section headings stable — the generators
key off them.

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
- **Confidence:** high / medium / low, with a one-line basis.
- **Gaps:** what's thin (e.g., "no external-formal emails observed").

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
- Confidence: high — large, recent, clean sample.
- Gaps: few work-channel (vs. DM) samples.
```
