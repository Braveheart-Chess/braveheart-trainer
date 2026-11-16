#!/usr/bin/env bash
# The pinned engine's crates/search/src/nnue.rs, which lists the net shapes it
# reads (WIDTHS, OUTPUT_BUCKETS, KING_BUCKETS) and its nets: prints the path of
# the copy Cargo fetched for the commit Cargo.lock pins.
#
#   ci/engine-nnue-rs.sh   ->   ~/.cargo/git/checkouts/braveheart-*/3fd0223/crates/search/src/nnue.rs
set -euo pipefail
cd "$(dirname "$0")/.."
manifest=$(cargo metadata --format-version 1 --locked |
  python3 -I -c 'import json, sys; print(next(p["manifest_path"] for p in json.load(sys.stdin)["packages"] if p["name"] == "braveheart-search"))')
nnue="$(dirname "$manifest")/src/nnue.rs"
[ -f "$nnue" ] || { echo "engine-nnue-rs: $nnue does not exist" >&2; exit 1; }
echo "$nnue"
