#!/usr/bin/env bash
# Verifies the "Resolving the profile" canonical resolution-order string is
# byte-identical across every file that quotes it.
#
# Background: docs/design/profile-durability.md, "The canonical
# resolution-order string" — this exact block must appear unparaphrased in
# voice-doc, voice-email, voice-chat, voice-rewrite, voice-harvest, and
# voice-tune (six consumers), plus once more as the authoritative copy in
# voice-profile/SKILL.md (seven files total). A paraphrase or reflow in any
# one of them silently reintroduces the per-generator path-resolution drift
# this story fixed (issue #4).
#
# Usage: scripts/check-canonical-resolution-string.sh
# Exit 0 and silent on success; exit 1 with a diff on drift or a missing file.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

FILES=(
  "skills/voice-profile/SKILL.md"
  "skills/voice-doc/SKILL.md"
  "skills/voice-email/SKILL.md"
  "skills/voice-chat/SKILL.md"
  "skills/voice-rewrite/SKILL.md"
  "skills/voice-harvest/SKILL.md"
  "skills/voice-tune/SKILL.md"
)

# The block is a markdown blockquote starting at the line that introduces it
# and running to (but not including) the first blank line that follows.
extract_block() {
  awk '
    /\*\*Resolving the profile\.\*\*/ { capture=1 }
    capture {
      if ($0 == "") exit
      print
    }
  ' "$1"
}

status=0
reference_file=""
reference_block=""

for f in "${FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f does not exist (expected one of the 7 canonical-string files)" >&2
    status=1
    continue
  fi

  hits=$(grep -c '\*\*Resolving the profile\.\*\*' "$f" || true)
  if [[ "$hits" -eq 0 ]]; then
    echo "MISSING BLOCK: $f has no 'Resolving the profile' block" >&2
    status=1
    continue
  elif [[ "$hits" -gt 1 ]]; then
    echo "DUPLICATE: $f quotes the block $hits times (expected exactly 1)" >&2
    status=1
    continue
  fi

  block=$(extract_block "$f")

  if [[ -z "$reference_file" ]]; then
    reference_file="$f"
    reference_block="$block"
    continue
  fi

  if [[ "$block" != "$reference_block" ]]; then
    echo "DRIFT: $f does not match $reference_file byte-for-byte:" >&2
    diff <(printf '%s\n' "$reference_block") <(printf '%s\n' "$block") >&2 || true
    status=1
  fi
done

if [[ "$status" -eq 0 ]]; then
  echo "OK: canonical resolution-order string is byte-identical across all ${#FILES[@]} files."
fi

exit "$status"
