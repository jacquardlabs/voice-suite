# Epic pre-mortem: audit-fixes

Cross-story failure modes for the `audit-fixes` epic (issues #4, #5, #6, #7, #9, #10),
verified at the epic finale by `@agent-premortem-auditor` against the finished
changeset.

1. **Merge conflicts on shared generator files despite the dependency edges.**
   `profile-durability`, `fidelity-consistency`, and `routing-tells-consolidation` all
   touch the same handful of SKILL.md files (voice-doc, voice-email, voice-chat,
   voice-rewrite, voice-harvest, voice-profile). The DAG serializes the pairs with the
   highest content overlap, but the driver's one-merge-fix-attempt-then-park is the
   real backstop — if two supposedly-independent stories (e.g. `evidence-standards`
   touching voice-harvest's synthesis step, and `profile-durability` touching
   voice-profile's frontmatter) land close together, expect at least one merge-fix
   cycle.

2. **Resolution-order text gets paraphrased instead of quoted.**
   `profile-durability`'s worker establishes one canonical path-resolution order.
   Every downstream story that touches profile loading (`fidelity-consistency`,
   `voice-card-export`) must quote that exact committed text, not paraphrase it —
   paraphrasing recreates the exact duplication bug issue #5 exists to fix.

3. **`_format.md`'s section headings are load-bearing.**
   "Keep the section headings stable — the generators key off them" (`_format.md`).
   `evidence-standards` adds a `## Pending observations` section; the worker must not
   rename or reorder `## Traits`/`## Exemplars`/`## Anti-patterns`/
   `## Strunk exemptions`/`## Coverage` while doing so, or every generator's parsing
   assumption breaks silently — no test suite will catch this.

4. **`routing-tells-consolidation` silently claims issue #8's territory.**
   Issue #7's "unclaimed territory" item lists commit/PR prose as undecided. Issue #8
   (git-history harvest source) was DEFERRED, not approved — the worker must mark
   commit/PR prose as explicitly out-of-scope-pending-#8, not assign it to an existing
   generator as a shortcut.

5. **No automated test suite — evidence must be redefined per story, or audit/
   acceptance false-fail.** This is a prompt-only repo. Every story's acceptance
   criteria (recorded in the ledger) are concrete, observable checks — file exists,
   string appears exactly once, heading text unchanged, two files quote identical
   text — not "tests pass." Gate agents and workers need this framing up front, or a
   worker reports "blocked: no test framework" and stalls on a non-problem.

6. **`voice-card-export` hardcodes the old plugin-managed path out of habit.**
   It depends on `profile-durability`, but if the worker is briefed only on acceptance
   criteria without the actual committed resolution-order text, it may copy the
   pre-fix pattern from an existing generator it reads for reference instead of the
   post-fix stable path.

7. **`voice-check-fidelity-scorer` re-derives its own tells rubric instead of
   consuming `ai-tells.md`.** Its entire premise (issue #9's own text) is reusing the
   consolidated list from `routing-tells-consolidation` — the dependency edge exists
   exactly to prevent a fifth divergent list; the worker's brief must point at the
   committed `references/ai-tells.md` path explicitly.
