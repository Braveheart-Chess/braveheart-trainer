# braveheart-trainer

The trainer for Braveheart's NNUE nets, and the record of every net it has made.

- **`trainer/`** trains a net with [bullet](https://github.com/jw1912/bullet),
  pinned to one commit, on the self-play positions.
- **`nnue-eval`** checks every trained net with the engine's own quantized
  evaluation before it is kept.
- **Train** and **GPU smoke** run on dedicated GPU instances.
- **The ledger**, [docs/nets.md](docs/nets.md), records every net: its data, its
  settings, its losses and its results.

The engine is [Braveheart-Chess/braveheart](https://github.com/Braveheart-Chess/braveheart);
the positions come from [Braveheart-Chess/braveheart-selfplay](https://github.com/Braveheart-Chess/braveheart-selfplay).
The engine adopts a net by an ordinary pull request, measured by its own SPRT.

## Moved from the engine repository

These files moved here from `Braveheart-Chess/braveheart` at
[`1a25b13`](https://github.com/Braveheart-Chess/braveheart/commit/1a25b1375049c88b2c9cf01d26c90216f5f65d88)
on 2026-11-16, with their history. `crates/tools/src/bin/nnue_eval.rs` became
`crates/nnue-eval/src/main.rs`. Pull request numbers in the older commit messages
refer to the engine repository.

**Interim.** Until the data move, the positions and the nets stay in
`s3://jwall-engineering-braveheart-nnue`, owned by the engine's project, and Train
and GPU smoke keep running from the engine repository. This repository gets its
own bucket, `jwall-engineering-braveheart-trainer-nets`, at the data move.
