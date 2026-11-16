# Contributing

The short version: one-line Conventional Commits, every change through a pull request, squash or rebase merges only, releases cut by Release Please, and every net checked against one pinned engine. [AGENTS.md](AGENTS.md) has the rules for nets and the research record.

## Workflow

1. Branch from `main`.
2. Make the change. Keep the code formatted (`cargo fmt` in both workspaces) and run the local checks below.
3. Open a PR with a typed template (see below). The PR title must be a valid Conventional Commit.
4. Merge with **squash** or **rebase**. Merge commits are disabled and history stays linear.

Direct pushes to `main` are not allowed. The only exception was the initial scaffold commit.

## Local checks

```sh
cargo fmt --all --check
cargo fmt --manifest-path trainer/Cargo.toml --all --check
cargo clippy --workspace --all-targets --all-features --locked -- -D warnings
cargo clippy --manifest-path trainer/Cargo.toml --all-targets --locked -- -D warnings
cargo test --workspace --locked
cargo test --manifest-path trainer/Cargo.toml --locked
npm ci && npm run engine:fetch && npm run nnue:diagrams:check && npm test
```

The trainer is built, linted and tested here without a GPU backend; Train and GPU smoke build it with `--features cuda` on the instance. CI runs the same checks on every pull request. Optional local hooks catch mistakes before they are pushed:

```sh
pre-commit install --hook-type commit-msg --hook-type pre-commit
```

## Changing what a net is trained or checked with

- **The engine pin.** `Cargo.toml` and `trainer/Cargo.toml` pin `braveheart-core` and `braveheart-search` to the same engine tag, and `crates/nnue-eval/tests/engine_pin.rs` fails if the locks disagree. `crates/nnue-eval/tests/golden.rs` pins how the engine scores eight positions with its embedded net, with values from the engine's own `nnue-eval`. Moving the pin is its own PR: it moves both, updates the golden values, re-runs `npm run engine:fetch` and the diagram check, and says which net is first checked against the new engine.
- **The trainer.** The architecture, schedule, quantization, file format and the bullet commit are part of every net's provenance (`training.json`). A change to any of them is a `feat` or a `fix` that says which net first uses it; a `perf` or `refactor` PR changes none of them.
- **A new net's architecture** gets a snapshot: add its manifest under `docs/nnue-architectures/manifests/`, then `npm run nnue:diagrams`.

## Commit messages: one line, nothing else

Every commit message is a single line:

```
type(scope)?: subject
```

- At most 100 characters.
- `type` is one of `feat`, `fix`, `docs`, `chore`, `refactor`, `ci`, `build`, `perf`, `style`, `test`, `revert`.
- Breaking changes are marked with `!`, for example `feat!: drop the v1 net format`.
- The only content allowed after the header is a blank line followed by `Co-authored-by: Name <email>` trailers.
- No body text. Details belong in the PR description.

commitlint enforces this with `@commitlint/config-conventional` plus a local rule, `only-coauthor-trailers` (`tools/commitlint/only-coauthor-trailers.mjs`), which fails on any line after the header that is not blank or a `Co-authored-by` trailer. CI runs it over every commit in the PR range, so a rebase merge never lands a non-conforming commit on `main`.

### Why the PR title matters

Squash merges use the PR title as the commit message on `main`, and Release Please reads those messages to decide the next version and to write `CHANGELOG.md`. A `feat` bumps the minor version, a `fix` bumps the patch, and `!` bumps the major (the minor while pre-1.0). CI lints the title with the same rules.

### Dependabot PRs

Dependabot cannot write one-line, lowercase commit messages, so its PRs skip the commit message check and the title check. Merge them with **squash** and a lowercase Conventional Commit subject, for example:

```sh
gh pr merge <n> --squash --subject "ci: bump actions/checkout from 6 to 7"
```

A Dependabot PR that moves the engine or bullet changes what nets are trained or checked with: see [Changing what a net is trained or checked with](#changing-what-a-net-is-trained-or-checked-with).

## Pull request templates

Templates live in `.github/PULL_REQUEST_TEMPLATE/`, one per type: `feat.md`, `perf.md`, `fix.md`, `docs.md`, `chore.md`, `refactor.md`, `ci.md`. Pick one with

```sh
gh pr create --template fix.md
```

## Releases

Release Please keeps a release PR open on `main`. Merging it tags `vX.Y.Z` and writes `CHANGELOG.md`; nobody edits that by hand. The crates' own versions stay as they are: nothing reads them, and a net records the commit it was trained from. Release Please only cuts a release when a commit of a type that appears in `CHANGELOG.md` lands on `main`: `feat`, `fix`, `perf`, `revert` or `docs`. `chore`, `ci`, `build`, `refactor`, `style` and `test` never release on their own.
