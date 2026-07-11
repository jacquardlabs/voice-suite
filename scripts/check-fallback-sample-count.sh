#!/usr/bin/env bash
# Verifies the no-profile fallback sample count is stated exactly once -- in
# voice-profile's canonical fidelity procedure -- and that none of the four
# generator SKILL.md files restate a competing count of their own.
#
# Background: docs/design/fidelity-consistency.md, "Converge the fallback
# sample count to one number, stated once, in the canonical copy's step 1."
# Before this story: voice-doc asked for "2-4 samples," voice-email for "2-3
# pasted real emails," voice-rewrite for "2-4 pasted samples," and voice-chat
# stated no number at all. The dedup's durability depends on the four
# generators pointing at the canonical figure rather than restating it -- a
# later edit that re-inlines a number into any one of them silently
# reintroduces the divergence with nothing flagging it (premortem item 3,
# docs/studious/premortems/fidelity-consistency.md).
#
# Note: this deliberately does not flag voice-chat's "a few of the user's
# real messages" register-flavor phrasing -- that qualitative phrase (not a
# competing numeral) is the design's stated register flavor for chat, kept
# alongside the pointer to the canonical count. It also does not flag
# voice-doc's Strunk rule-number ranges (e.g. "10-15", "1-9, 16-17") --
# those are craft-layer rule references, not sample-count numerals, and
# don't sit next to fallback/sample/paste language.
#
# Usage: scripts/check-fallback-sample-count.sh
# Exit 0 and silent on success; exit 1 with the offending line(s) on drift.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

CANONICAL_FILE="skills/voice-profile/SKILL.md"
CANONICAL_COUNT="2–4"

GENERATORS=(
  "skills/voice-doc/SKILL.md"
  "skills/voice-email/SKILL.md"
  "skills/voice-chat/SKILL.md"
  "skills/voice-rewrite/SKILL.md"
)

# A standalone sample-count numeral: a digit-dash-digit range immediately
# followed by "sample(s)", "pasted", or "real" -- the words that introduced
# the fallback ask in the pre-fix text of all four generators. Markdown
# source soft-wraps mid-sentence, so a numeral and its following word can
# land on different lines (this bit voice-rewrite's original "2-4\npasted
# samples" during authoring) -- flatten single newlines to spaces first so
# the pattern matches across a wrap the way a reader would.
PATTERN='[0-9]+[–-][0-9]+[[:space:]]+(pasted|samples?|real )'

flatten() {
  perl -0777 -pe 's/\n(?!\n)/ /g' "$1"
}

status=0

if [[ ! -f "$CANONICAL_FILE" ]]; then
  echo "MISSING: $CANONICAL_FILE does not exist" >&2
  exit 1
fi

hits=$(flatten "$CANONICAL_FILE" | { grep -oE "${CANONICAL_COUNT}[[:space:]]+samples" || true; } | wc -l | tr -d ' ')
if [[ "$hits" -ne 1 ]]; then
  echo "CANONICAL COUNT MISSING OR DUPLICATED: $CANONICAL_FILE states \"${CANONICAL_COUNT} samples\" $hits time(s) (expected exactly 1, in the fidelity procedure's step 1)" >&2
  status=1
fi

for f in "${GENERATORS[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f does not exist (expected one of the 4 generator files)" >&2
    status=1
    continue
  fi

  if hits=$(flatten "$f" | grep -noE "$PATTERN"); then
    echo "RESTATED COUNT: $f states its own sample-count numeral instead of pointing at $CANONICAL_FILE's fidelity procedure (step 1):" >&2
    echo "$hits" >&2
    status=1
  fi
done

if [[ "$status" -eq 0 ]]; then
  echo "OK: fallback sample count is stated once, in voice-profile's canonical fidelity procedure; no generator restates a competing count."
fi

exit "$status"
