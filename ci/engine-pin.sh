#!/usr/bin/env bash
# The engine this repository is pinned to, from Cargo.lock: prints
# `VERSION COMMIT` of braveheart-search (the same pin build.rs records in every
# manifest). Run from anywhere; reads the Cargo.lock next to ci/, or the one
# given.
#
#   ci/engine-pin.sh [Cargo.lock]   ->   0.54.0 3fd0223c949d28dc391f86e1790bffde28ff04e3
set -euo pipefail
lock=${1:-"$(cd "$(dirname "$0")/.." && pwd)/Cargo.lock"}
awk '
  /^name = "braveheart-search"$/ { found = 1; next }
  found && /^version = / { gsub(/"/, "", $3); version = $3 }
  found && /^source = / { n = split($0, part, "#"); sha = part[n]; gsub(/"/, "", sha); print version, sha; done = 1; exit }
  found && /^\[\[package\]\]/ { exit }
  END { if (!done) exit 1 }
' "$lock" | {
  read -r version sha || { echo "engine-pin: no braveheart-search from git in $lock" >&2; exit 1; }
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$sha" =~ ^[0-9a-f]{40}$ ]] \
    || { echo "engine-pin: unexpected pin '$version $sha' in $lock" >&2; exit 1; }
  echo "$version $sha"
}
