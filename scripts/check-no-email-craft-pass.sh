#!/usr/bin/env bash
# Verifies no generator's craft-pass step authorizes a Strunk/craft edit on
# email-scale content -- the canonical fidelity procedure
# (voice-profile/SKILL.md step 4) and `_format.md`'s contract ("no craft
# pass runs on [email/chat] by default") both restrict the craft pass to
# long-form drafting and doc-scale rewrites only. Email never gets one, at
# any formality or length.
#
# Background: docs/design/fidelity-consistency.md Open question 2 /
# docs/studious/premortems/audit-fixes-epic.md item 11. voice-rewrite's own
# Step 5 once read "Email-scale: only if long and formal" -- borrowing the
# longform Strunk-exemption list for long, formal email-scale rewrites,
# after voice-email had already been fixed (this same story) to never run a
# craft pass on email, at any formality or length. That's exactly the
# cross-register borrowing fidelity-consistency removed from voice-email;
# this guard keeps it from resurfacing in voice-rewrite (or drifting into
# voice-doc/voice-chat, which don't draft email but are cheap to include).
#
# Note: markdown source soft-wraps mid-sentence, so "Email-scale: only if
# long and" / "formal." can land on different lines (this is exactly how
# voice-rewrite's original text was authored) -- flatten single newlines to
# spaces first, the same technique check-fallback-sample-count.sh uses, so
# the pattern matches across a wrap the way a reader would.
#
# Usage: scripts/check-no-email-craft-pass.sh
# Exit 0 and silent on success; exit 1 with the offending line(s) on drift.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

FILES=(
  "skills/voice-doc/SKILL.md"
  "skills/voice-email/SKILL.md"
  "skills/voice-chat/SKILL.md"
  "skills/voice-rewrite/SKILL.md"
)

flatten() {
  perl -0777 -pe 's/\n(?!\n)/ /g' "$1"
}

# A conditional authorization: "email" (as in "email-scale") followed,
# within the same sentence, by a condition word ("if"/"when") and a
# formality/length qualifier ("long"/"formal") -- the exact shape of the bug
# that let voice-rewrite borrow the longform Strunk-exemption list for long,
# formal email-scale rewrites. Bounded to one sentence (no period in
# between) so it doesn't span unrelated later sentences.
BAD_PATTERN='[Ee]mail[a-zA-Z-]*[^.]*\b(if|when)\b[^.]*\b(long|formal)\b'

status=0

for f in "${FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f does not exist (expected one of the 4 generator files)" >&2
    status=1
    continue
  fi

  if hits=$(flatten "$f" | grep -noE "$BAD_PATTERN"); then
    echo "CONDITIONAL EMAIL CRAFT PASS: $f authorizes a craft pass on email under some condition -- email never gets one, at any formality or length:" >&2
    echo "$hits" >&2
    status=1
  fi
done

# voice-email and voice-rewrite must each say plainly that email-scale gets
# no craft pass -- not merely omit the bad pattern above, which a
# differently worded conditional could still dodge.
for f in "skills/voice-email/SKILL.md" "skills/voice-rewrite/SKILL.md"; do
  if ! flatten "$f" | grep -qiE 'no craft pass runs on email|[Ee]mail-scale[^.]*: *never|[Ee]mail-scale and chat-scale[^.]*never'; then
    echo "NO EXPLICIT NEVER: $f does not plainly state that email-scale gets no craft pass" >&2
    status=1
  fi
done

if [[ "$status" -eq 0 ]]; then
  echo "OK: no generator authorizes a craft pass on email-scale content; voice-email and voice-rewrite both state it plainly."
fi

exit "$status"
