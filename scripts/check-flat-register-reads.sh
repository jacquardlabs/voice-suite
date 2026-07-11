#!/usr/bin/env bash
# Verifies the four generation skills, plus voice-check, read register files
# flat from the resolved profile directory, matching how voice-harvest
# writes them and what the canonical "Resolving the profile" block says to
# do.
#
# Background: the canonical block (see
# scripts/check-canonical-resolution-string.sh) says to "Read `global.md`
# plus the matching register file (`longform.md` / `email.md` / `chat.md`)
# from whichever directory step 1 or 2 resolved to" — flat, no subfolder.
# voice-harvest's Output step writes global.md/longform.md/email.md/chat.md
# flat into that same resolved directory. A consumer that instead reads
# `references/longform.md` (etc.) from the resolved directory is quoting the
# canonical block correctly but not following it, and will silently miss
# the exemplar-bearing register file voice-harvest just wrote (issue #4
# follow-up: this exact drift shipped once already and was caught by the
# profile-durability acceptance gate). voice-check reads one register file
# the same way the four generators do (see "Resolving the profile" in its
# own SKILL.md), so it belongs in this same guard.
#
# Note: this deliberately does NOT scan voice-profile/SKILL.md. That file's
# own `references/global.md` mentions describe the *skill bundle's own*
# directory layout (skills/voice-profile/references/*.md), which is itself
# the resolved directory for the claude.ai fallback (step 2) — those files
# already sit flat inside references/, so `references/global.md` there is
# correct, not an instance of this bug.
#
# Usage: scripts/check-flat-register-reads.sh
# Exit 0 and silent on success; exit 1 with the offending line(s) on drift.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

FILES=(
  "skills/voice-doc/SKILL.md"
  "skills/voice-email/SKILL.md"
  "skills/voice-chat/SKILL.md"
  "skills/voice-rewrite/SKILL.md"
  "skills/voice-check/SKILL.md"
)

# Matches a register-file read still prefixed with references/, e.g.
# `references/longform.md`, `references/email.md`, `references/chat.md`,
# or the brace form `references/{chat,email,longform}.md`.
PATTERN='references/(\{[a-z,]+\}|longform|email|chat)\.md'

status=0

for f in "${FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f does not exist (expected one of the ${#FILES[@]} tracked files)" >&2
    status=1
    continue
  fi

  if hits=$(grep -nE "$PATTERN" "$f"); then
    echo "STALE PREFIX: $f still reads a register file under references/ (should be flat):" >&2
    echo "$hits" >&2
    status=1
  fi
done

if [[ "$status" -eq 0 ]]; then
  echo "OK: all ${#FILES[@]} tracked files read register files flat from the resolved directory."
fi

exit "$status"
