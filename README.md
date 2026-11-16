<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/Braveheart-Chess/braveheart-branding/main/banner-dark.png">
    <img src="https://raw.githubusercontent.com/Braveheart-Chess/braveheart-branding/main/banner-light.png" alt="Braveheart" width="640">
  </picture><br>
  <sub>Logo © the artist, used under licence. All rights reserved; not covered by this repository's licence (<a href="https://github.com/Braveheart-Chess/braveheart-branding#licence">details</a>).</sub>
</p>

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

**Until the cutover** the nets are in two buckets: they were copied, key for
key, from `s3://jwall-engineering-braveheart-nnue`, owned by the engine's
project, to this project's `s3://jwall-engineering-braveheart-trainer-nets` on
2026-11-16, and audited:

- [docs/nets.md](docs/nets.md) is the ledger since the copy; the engine's was
  until then.
- The Train and GPU smoke workflows are ported to this project and both
  buckets, and wait for the cutover ([AGENTS.md](AGENTS.md#until-the-cutover)).

## Building

Two Cargo workspaces, so bullet's GPU backends never reach nnue-eval's build:

| Path | What it is |
|:--|:--|
| `crates/nnue-eval/` | The engine's static evaluation of positions with a net, checked against the trainer's (root workspace, `Cargo.lock`) |
| `trainer/` | The bullet trainer: `prepare`, `train` and `validate` (its own workspace and `trainer/Cargo.lock`) |
| `ci/` | The task scripts the workflows run |
| `docs/` | The pipeline, the ledger and the architecture snapshots |
| `tools/nnue-diagrams/` | The architecture snapshots' generator and check |

Both are pinned to one engine release (`Cargo.toml` and `trainer/Cargo.toml`;
a test checks the two locks agree), and the trainer to one bullet commit.

```sh
cargo build --release --locked --bin nnue-eval
cargo test --workspace --locked                       # includes nnue-eval's golden test
cd trainer && cargo build --release --locked --features cuda   # or metal
cargo test --locked                                   # from trainer/: no backend needed
```

`crates/nnue-eval/tests/golden.rs` pins how nets are checked: nnue-eval scores
eight positions with the engine's embedded net exactly as the engine's own
nnue-eval did. The architecture snapshots are checked against the pinned
engine's embedded and retired nets:

```sh
npm ci
npm run engine:fetch          # the engine at the commit Cargo.lock pins, into .engine/
npm run nnue:diagrams:check
```
