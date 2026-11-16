# Guidance for coding agents

This repository trains Braveheart's NNUE nets and keeps their record: `trainer/` trains a net with bullet, `nnue-eval` checks every trained net with the engine's own quantized evaluation, and `docs/nets.md` is the ledger. Read [README.md](README.md) for the layout, [docs/training.md](docs/training.md) for the pipeline, [docs/nets.md](docs/nets.md) for the ledger and [CONTRIBUTING.md](CONTRIBUTING.md) for the full rules. The rules below are the ones you MUST follow.

## Rules

- **Never push to `main`.** Every change goes through a pull request on a branch. There are no exceptions after the initial scaffold.
- **Commits are a single line**: `type(scope)?: subject`, at most 100 characters. Allowed types: `feat`, `fix`, `docs`, `chore`, `refactor`, `ci`, `build`, `perf`, `style`, `test`, `revert`. The only thing allowed after the header is a blank line and `Co-authored-by: Name <email>` trailers. No body text. Put details in the PR description.
- **Open PRs with a typed template** and fill in every section:

  ```sh
  gh pr create --template <feat|perf|fix|docs|chore|refactor|ci>.md
  ```

  The PR title MUST be a valid Conventional Commit; squash merges use it as the commit message.
- **Run the repo's checks locally before opening the PR** (see below).
- **Never delete or overwrite a net or its record.** Every net trained, kept or not, keeps its `training.json`, losses, split and log, and its row in `docs/nets.md`. No workflow, script or command in this repository deletes from the dataset bucket.
- **One engine, pinned.** `Cargo.toml` pins `braveheart-core` and `braveheart-search` to one engine release, and `trainer/Cargo.toml` pins the same tag for its tests; `crates/nnue-eval/tests/engine_pin.rs` checks the two locks agree. `crates/nnue-eval/tests/golden.rs` pins how that engine scores positions with its embedded net, with values from the engine's own `nnue-eval`. Moving the pin is its own PR: it updates the golden values and says which net is first checked against the new engine. Never update a golden value to make CI pass.
- **The trainer's settings are part of every net's provenance.** The architecture, schedule, quantization, file format and the bullet commit in `trainer/Cargo.toml` are recorded in each net's `training.json`. A change to any of them is a `feat` (or a `fix`) that says which net first uses it. A `perf` or `refactor` PR changes none of them.
- **Every experiment updates `docs/`.** Training, a net's SPRT and rating, and one-off measurements all get recorded, including smoke tests and failed, cancelled, interrupted and dropped runs. See [Experiments and the research record](#experiments-and-the-research-record).

## Until the data move

The positions and the nets still live in `s3://jwall-engineering-braveheart-nnue`, owned by the engine's project, and Train and GPU smoke still run from [Braveheart-Chess/braveheart](https://github.com/Braveheart-Chess/braveheart).

- **The engine's [docs/nets.md](https://github.com/Braveheart-Chess/braveheart/blob/main/docs/nets.md) is the ledger until then.** The copy here is a snapshot from engine commit `1a25b13`; record nothing in it. It is refreshed from the engine's at the data move, together with the architecture snapshots.
- **The workflows and `ci/` scripts here are not ported yet.** They came over with their history: they still build `-p braveheart-tools`, run as the engine's project, and record the repository commit as `engine_commit`, which here would be the trainer's. `jwall-engineering-sites.yaml` declares no dataset, so Train stops at its first step, and GPU smoke's role trusts only the engine repository. Don't add a dataset or run them; porting them is part of the data move.

## Experiments and the research record

This project is research: a result counts only when someone else can reproduce it and check it from the record.

| When you run | Record it in |
|:--|:--|
| Training, a net's SPRT, a release's rating of a net | [docs/nets.md](docs/nets.md) (the engine's until the data move), and its "What we've learned" and "Next experiments" when the result changes what to try next |
| A new net's architecture | Its snapshot in [docs/nnue-architectures/](docs/nnue-architectures/README.md) (`npm run nnue:diagrams`) |
| A design measurement (king buckets, schedules, quantization) | That topic's page in `docs/` |
| Datagen, a Relabel run, an audit | [braveheart-selfplay's docs/datasets.md](https://github.com/Braveheart-Chess/braveheart-selfplay/blob/main/docs/datasets.md) (the engine's until the data move) |

- **Record it promptly.** Use the same PR when the experiment has one. Otherwise open a docs PR when the run ends, before another experiment builds on the result.
- **Decide before you run.** Write down the question, the one thing that changes, what stays the same and what result would keep or drop it. Don't move the criterion after seeing the result.
- **Make it reproducible.** Record the commit or tag of this repository and of the engine it pins, the workflow inputs or exact command, the run id, seeds, the generations and label sets, each net's id and SHA-256, the bullet commit, and the hardware and market.
- **Use primary sources.** Take numbers from `training.json`, the losses and validation files, a PR's SPRT comment or release notes, never from progress lines, memory or another document. Link the source. Label estimates, such as costs, and local measurements as what they are.
- **Audit before you build on it.** Train only on generations with a full audit's GO and label sets with their recorded audit. Name a net's data by its generations and each one's label set, and compare losses only on identical held-out positions and labels. Where a check could pass without testing anything, add a negative control.
- **Say what wasn't verified.** Name any check you skipped or couldn't run, and why. When you check a ledger against its sources, add the result to its audit log, gaps included.
- **Keep every result and correct in the open.** Never delete or reword a failed or disappointing result. Record every attempt, including reclaimed legs and re-runs, and the gate in force when the decision was made. A later rule doesn't rewrite an earlier decision; note how the two differ.

## Before opening a PR

```sh
cargo fmt --all --check
cargo fmt --manifest-path trainer/Cargo.toml --all --check
cargo clippy --workspace --all-targets --all-features --locked -- -D warnings
cargo clippy --manifest-path trainer/Cargo.toml --all-targets --locked -- -D warnings
cargo test --workspace --locked
cargo test --manifest-path trainer/Cargo.toml --locked
npm ci && npm run engine:fetch && npm run nnue:diagrams:check && npm test
```

## Things that need the owner

Repository secrets and variables, the release bot app installation, repository settings, AWS (applies happen through the infra repository's workflows) and anything that writes to the dataset bucket. List them in the PR instead of attempting them.
