#!/usr/bin/env bash
# Verifies the AI-tells vocabulary is sourced from exactly one canonical
# file -- skills/voice-profile/references/ai-tells.md -- and that no other
# file under skills/ restates it, with one stated exception.
#
# Background: docs/design/routing-tells-consolidation.md. Before this story,
# four independent, overlapping-but-not-identical copies of the tells
# vocabulary existed (voice-profile, voice-doc [already dedup'd by
# fidelity-consistency], voice-rewrite, voice-harvest) and had already
# drifted (DESIGN.md's Vocabulary section documented the divergence). This
# guard's durability depends on every consumer pointing at ai-tells.md
# instead of restating it -- a later edit that re-inlines the vocabulary
# into any one of them silently reintroduces the drift with nothing
# flagging it (design doc, Open question 4).
#
# The one deliberate exception: skills/voice-harvest/references/relay-prompt.md
# embeds its own literal copy because the prompt runs on a Claude surface
# with no file access to this skill's references/ -- it cannot point at
# ai-tells.md the way every other consumer does. See that file's own note.
#
# This deliberately scopes to skills/ only, not the whole repo -- DESIGN.md
# and docs/design/routing-tells-consolidation.md legitimately quote the
# vocabulary as documentation of the fix itself, and a repo-wide grep would
# false-positive on both.
#
# This also deliberately excludes skills/voice-email/SKILL.md. Its fidelity
# check names a short parenthetical example ("no 'I hope this email finds
# you well', no reflexive bulleting, no over-formal closers") that shares
# the same underlying vocabulary but was flagged in the design doc (Open
# question 2) as an in-spirit, not literally-named, inclusion -- left for
# the gate to confirm rather than resolved unilaterally by this story.
#
# Usage: scripts/check-ai-tells-single-source.sh
# Exit 0 and silent on success; exit 1 with the offending line(s) on drift.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

CANONICAL_FILE="skills/voice-profile/references/ai-tells.md"
RELAY_PROMPT_EXCEPTION="skills/voice-harvest/references/relay-prompt.md"
EXCLUDED_FILE="skills/voice-email/SKILL.md"

# Consumers that must point at the canonical file by reference.
POINTER_FILES=(
  "skills/voice-profile/SKILL.md"
  "skills/voice-rewrite/SKILL.md"
  "skills/voice-harvest/SKILL.md"
)

# Distinctive fragments of the pre-consolidation restatements. A match
# outside the canonical file or its stated exception means the vocabulary
# was restated instead of pointed at.
PATTERN='delve|leverage|streamline|bolded triads|reflexive bullets|hedge-free over-confidence|finds you well'

status=0

if [[ ! -f "$CANONICAL_FILE" ]]; then
  echo "MISSING: $CANONICAL_FILE does not exist" >&2
  exit 1
fi

if [[ ! -f "$RELAY_PROMPT_EXCEPTION" ]]; then
  echo "MISSING: $RELAY_PROMPT_EXCEPTION does not exist (expected relay-prompt.md extraction)" >&2
  exit 1
fi

while IFS= read -r -d '' f; do
  case "$f" in
    "$CANONICAL_FILE"|"$RELAY_PROMPT_EXCEPTION"|"$EXCLUDED_FILE") continue ;;
  esac

  if hits=$(grep -inE "$PATTERN" "$f"); then
    echo "RESTATED VOCABULARY: $f restates AI-tells vocabulary instead of pointing at $CANONICAL_FILE:" >&2
    echo "$hits" >&2
    status=1
  fi
done < <(find skills -name '*.md' -print0)

for f in "${POINTER_FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f does not exist (expected one of the 3 canonical consumers)" >&2
    status=1
    continue
  fi

  if ! grep -q 'ai-tells.md' "$f"; then
    echo "NO POINTER: $f does not reference ai-tells.md (expected a pointer, not a restatement)" >&2
    status=1
  fi
done

if [[ "$status" -eq 0 ]]; then
  echo "OK: AI-tells vocabulary is sourced from $CANONICAL_FILE alone; every consumer points at it; the relay-prompt exception is the only other copy."
fi

exit "$status"
