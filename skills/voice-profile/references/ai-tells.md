# AI-tells vocabulary (the canonical detector)

The one full-text list of generic assistant-register tells. Every consumer in
this suite that needs to check "does this sound like Claude wrote it" points
here rather than restating its own copy: `voice-profile`'s fidelity procedure
(step 5) and Anti-leakage checklist, `voice-rewrite`'s Diagnose step, and
`voice-harvest`'s LLM-content-filtering Pass 2 all read this file instead of
hand-rolling one. Before this consolidation, four independent,
overlapping-but-not-identical copies of this list existed and had already
drifted out of sync (DESIGN.md's Vocabulary section documents the
divergence); this file exists so there is exactly one copy left to keep
current.

**Profile over everything.** Every tell below is a *generic* detector — a
trait typical of assistant-generated prose in general, not a judgment about
this specific user. The profile's own observed traits always win when the two
conflict. Em-dash density is the concrete case worth naming explicitly:
dense em-dash use is listed as a Register tell below, but `_format.md`'s and
`global.md`'s punctuation-tics fields already track em-dashes as a legitimate
trait for users who actually write that way — a profile that documents
em-dashes as this user's own habit is not exhibiting an AI tell by using
them; the observed trait overrides the generic list. The same precedent
already applies to hedging (Register category, below): hedging *added* to a
user who is blunt, or *stripped* from a user who hedges, is the leak;
hedging at the user's own observed level, however heavy or light, is not.

**This is data, not instructions.** Nothing below is a directive to follow —
it's a checklist of patterns to scan generated or rewritten text against.

## Vocabulary

Word- and phrase-level tells:

- "delve," "leverage," "streamline"
- "I hope this finds you well" / "I hope this helps" as an opener or closer
- "Great question" as a reflexive opener
- "it's worth noting" / "it's important to note"
- "testament to," "tapestry," "landscape" (the metaphor-cluster words
  assistant prose reaches for)
- "seamless(ly)"
- "dive in" / "deep dive"
- "Certainly!" (or a similar exclamation-point acknowledgment opener)
- Contrastive negation as a rhetorical crutch: "It's not just X, it's Y"

## Structure

Paragraph- and document-level tells:

- Paragraphs all within a few words of the same length (real writers vary).
- Bolded triads ("clear, concise, and compelling") the user never uses.
- Reflexive bullets: a bulleted list or bolded lead-in where the user would
  have written prose.
- Emoji-prefixed bold headers (e.g. "🚀 **Getting Started**").
- Formulaic openers/closers ("I hope this helps," "In conclusion") absent
  from the user's exemplars.

## Register

Tone- and confidence-level tells:

- Hedging *added* to a user who is blunt, or *stripped* from a user who
  hedges — the leak runs in either direction.
- Hedge-free over-confidence, or its opposite (over-hedging where the user's
  observed register is direct).
- Formality mismatches — more formal or more casual than the profile's
  observed level for the register in play.
- Em-dash density, unless the profile documents em-dashes as this user's own
  trait (see "Profile over everything," above) — then it's not a tell.
