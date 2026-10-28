#!/usr/bin/env bash
# Merges pull requests one at a time, in the order given, once their required checks pass.
# Branch protection needs each branch up to date with main, so a BEHIND branch is updated
# first. Transient GitHub errors are retried with bounded backoff, and each PR gets a
# deadline so a stalled run is reported instead of waited on forever.
#
#   tool/merge_when_green.sh 61 62
set -uo pipefail
cd "$(dirname "$0")/.."
deadline_minutes="${DEADLINE_MINUTES:-45}"

retry() { # retry <command...>: up to 5 tries, 5s, 10s, 20s, 40s
  local n=0 delay=5
  until "$@"; do
    n=$((n + 1)); [ "$n" -ge 5 ] && return 1
    echo "  retry $n after ${delay}s: $*" >&2; sleep "$delay"; delay=$((delay * 2))
  done
}
field() { retry gh pr view "$1" --json "$2" -q ".$2"; }

for pr in "$@"; do
  start=$(date +%s)
  while true; do
    state=$(field "$pr" state) || { echo "#$pr: GitHub unreachable"; exit 1; }
    [ "$state" = MERGED ] && { echo "#$pr merged"; break; }
    [ "$state" = CLOSED ] && { echo "#$pr closed"; exit 1; }
    if [ $(( $(date +%s) - start )) -gt $((deadline_minutes * 60)) ]; then
      echo "#$pr: no progress in ${deadline_minutes} min; checks:"; gh pr checks "$pr"; exit 1
    fi
    status=$(field "$pr" mergeStateStatus)
    if [ "$status" = BEHIND ]; then
      retry gh pr update-branch "$pr" && echo "#$pr updated with main"
    elif retry gh pr merge "$pr" --merge >/dev/null 2>&1; then
      echo "#$pr merged"; break
    fi
    sleep 45
  done
done
