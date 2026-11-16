#!/bin/sh
# Check the engine out into .engine/ (gitignored) at the commit Cargo.lock pins.
# The NNUE diagram check compares the net manifests with that engine's embedded
# and retired nets, the same release nnue-eval checks nets against.
set -eu
cd "$(dirname "$0")/.."
sha=$(awk '/^name = "braveheart-search"$/ { f = 1 } f && /^source = / { print; exit }' Cargo.lock |
  sed -E 's/.*#([0-9a-f]{40})"$/\1/')
case "$sha" in
  "" | *[!0-9a-f]*) echo "fetch-engine: no braveheart-search commit in Cargo.lock" >&2; exit 1 ;;
esac
if [ "$(cat .engine/.commit 2>/dev/null || true)" = "$sha" ]; then
  echo "fetch-engine: .engine is already engine commit $sha"
  exit 0
fi
rm -rf .engine
git init -q .engine
git -C .engine fetch -q --depth 1 https://github.com/Braveheart-Chess/braveheart "$sha"
git -C .engine checkout -q FETCH_HEAD
echo "$sha" > .engine/.commit
echo "fetch-engine: .engine is engine commit $sha"
