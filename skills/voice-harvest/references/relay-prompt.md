# Relay prompt (chat-history-tools-unavailable fallback)

Used by `../SKILL.md`'s "Relay prompt fallback" section: when Claude chat
history tools are unavailable in the invoking session, deliver the prompt
below in a fenced code block so the user can copy it cleanly, to run on a
Claude surface that *does* have chat-history access (Claude Desktop, claude.ai
web). They paste the response back into the invoking session; treat it as
pre-filtered source material and proceed from `SKILL.md`'s Synthesis step.

**This file is deliberately self-contained, not a missed consolidation.** The
prompt below runs on a *different* Claude surface that has no file access to
this skill's `references/` folder, so it cannot point at
`voice-profile/references/ai-tells.md` or at `_format.md`'s confidence-tier
table the way every other consumer in this suite does — it has to carry its
own literal copies of both: the confidence-tier table, and the
vocabulary-spike examples ("delve, leverage, streamline...") the prompt uses
to filter LLM-contaminated samples. If `_format.md`'s Coverage table or
`ai-tells.md`'s Vocabulary category ever change, update both copies below
along with them — and `SKILL.md`'s Synthesis step, which cites the same
Coverage table by number.

````
Search my Claude conversation history using conversation_search and
recent_chats. I want to extract my authentic writing voice for a voice profile.
Follow these rules exactly:

**Source:** My user turns only — never assistant turns. Within my user turns,
skip any block that looks pasted rather than typed (a long, polished passage
inside an otherwise terse message is pasted content — length + register
discontinuity within a single turn is the tell).

**LLM-content filter (two passes):**
Pass 1 — build a trusted baseline from my oldest and most casual messages:
short replies, typo'd messages, quick reactions. Extract their stylometry:
typo/disfluency rate, sentence-length mean and variance, lexicon, punctuation
habits.
Pass 2 — score everything else against that baseline. Exclude samples with:
zero typos when my baseline has them, collapsed sentence-length variance,
vocabulary spikes (delve, leverage, streamline, "I hope this finds you well"),
bullet-heavy structure where my baseline is prose, or close match to a nearby
assistant turn.

**Bucket surviving samples into three registers:**
- Longform — multi-paragraph explanations, technical writeups, detailed
  descriptions
- Email — correspondence-register messages
- Chat — short replies, quick questions, reactions

**Confidence tiers (compute, don't pick):** count the samples surviving
filtering for this register and look up the tier below — never assert a
tier without a count.

| Register | High | Medium | Low |
|---|---|---|---|
| Chat | ≥100 messages | ≥30 messages | <30 messages |
| Email | ≥40 sent messages | ≥15 sent messages | <15 sent messages |
| Longform | ≥8 pieces | ≥3 pieces | <3 pieces |

Below medium: emit a trait only where at least 3 independent samples agree
on it, and never emit a Strunk exemption.

**Output this structure for each register:**

---
REGISTER: [longform / email / chat]

## Traits
[Quantified: sentence length mean + range, paragraph length, hedging level +
specific hedge words, formality level, signature lexicon words, never-words,
punctuation tics (em-dashes, ellipses, semicolons, parentheses), formatting
habits (prose vs bullets vs headers), structural habits (how I open, close,
transition)]

## Exemplars
[4–8 verbatim passages I actually wrote in this register, scrubbed of
names/numbers/identifying details. Span the range — include a terse one, a
careful one, a longer one.]

## Anti-patterns
[Never-does list: specific constructions, words, or formatting I demonstrably
avoid]

## Strunk exemptions
[Longform only: Strunk's Elements of Style rules I consistently break as part
of my voice. Format: "Rule N (name) — exempt: [one-line reason]". Only
consistent violations, not one-offs.]

## Coverage
- Sample count: [N messages]
- Date range: [earliest – latest]
- Confidence: [tier from the table above, with count] — [one-line basis],
  e.g. "medium (45 messages) — mostly DMs, few group threads"
- Gaps: [what's thin or unrepresented]
---

Also produce a GLOBAL TRAITS section — characteristics that hold across all
registers.

Output all four sections (Global + three registers) in sequence.
````
