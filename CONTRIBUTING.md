# Contributing

The short version: one-line Conventional Commits, every change through a pull request, squash or rebase merges only, releases cut by Release Please, and every net checked against one pinned engine. [AGENTS.md](AGENTS.md) has the rules for nets and the research record.

## Workflow

1. Branch from `main`.
2. Make the change. Keep the code formatted (`cargo fmt` in both workspaces) and run the local checks below.
3. Open a PR from the template (see below) and fill in every section. The PR title must be a valid commit header, scope included.
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
type(scope): subject
```

- At most 100 characters, with an imperative, lowercase subject and no trailing period.
- `type` is one of `feat`, `fix`, `perf`, `revert`, `docs`, `refactor`, `test`, `build`, `ci`, `style`, `chore`: the same set in every repository.
- `scope` is required: exactly one of the scopes below. A change that spans two is two pull requests, or takes the scope it is mostly about.
- Breaking changes are marked with `!`, for example `feat(trainer)!: drop the v1 net format`.
- The only content allowed after the header is a blank line followed by `Co-authored-by: Name <email>` trailers, in any letter case. No body text. Details belong in the PR description.

commitlint enforces this with `@commitlint/config-conventional` plus two local rules in `tools/commitlint/`: `only-coauthor-trailers` fails on any line after the header that is not blank or a `Co-authored-by` trailer, and `single-scope` fails on a list such as `feat(a,b)`. The fixtures in `tests/commitlint/` show accepted and rejected messages. CI lints every commit in the PR range, so a rebase merge never lands a non-conforming commit on `main`, and lints the PR title through the same config. The standard behind it is the [repository conventions](https://github.com/jwallace145/repository-template/blob/main/repository-conventions.md).

### Scopes

Every commit names exactly one of this repository's scopes. They are `SCOPES` in `commitlint.config.mjs`; this table mirrors it, in the same order, and `npm run test:commitlint` fails if they drift. Adding, renaming or removing a scope goes through a pull request like any other change.

| Scope | Covers |
| --- | --- |
| `trainer` | The bullet trainer in `trainer/`: architectures, schedules, quantization |
| `eval` | `crates/nnue-eval`: checking nets against the engine, and the golden test |
| `nets` | `docs/nets.md` and the record of every net |
| `diagrams` | `tools/nnue-diagrams` and `docs/nnue-architectures/` |
| `gpu` | The GPU training and smoke workflows and their tasks in `ci/` |
| `infra` | `jaws.yaml` and the Jaws workflows |
| `repo` | README, CONTRIBUTING, AGENTS, commitlint, the PR and issue templates, and repository tooling |
| `deps` | Dependency updates, mostly Dependabot's |
| `release` | Release Please's release pull requests and its config |

### Why the PR title matters

Squash merges use the PR title as the commit message on `main`, and Release Please reads those messages to decide the next version and to write `CHANGELOG.md`. A `feat` bumps the minor version, a `fix` bumps the patch, and `!` bumps the major (the minor while pre-1.0). CI lints the title through the same commitlint config as a commit, scope included. Release Please's own pull requests are titled `chore(release): release X.Y.Z`.

### Dependabot PRs

Dependabot writes its titles as `chore(deps): bump ...`, so they pass the title check as they are. Its commits carry a release-notes body, so its PRs skip the commit message check; merge them with **squash**, which lands only the title on `main`.

A Dependabot PR that moves the engine or bullet changes what nets are trained or checked with: see [Changing what a net is trained or checked with](#changing-what-a-net-is-trained-or-checked-with).

## Pull request template

One template, `.github/pull_request_template.md`: Summary, Why, Changes, Verification, Nets, and a checklist. `gh pr create` and the compare page both start from it. Fill in every section; write "n/a" rather than deleting one. For a fix, Why names the bug, its root cause and how to reproduce it.

## Issues

Open issues from the forms: **Bug**, **Feature** or **Task**. Blank issues are off.
## Releases

Release Please keeps a release PR open on `main`. Merging it tags `vX.Y.Z` and writes `CHANGELOG.md`; nobody edits that by hand. The crates' own versions stay as they are: nothing reads them, and a net records the commit it was trained from. Release Please only cuts a release when a commit of a type that appears in `CHANGELOG.md` lands on `main`: `feat`, `fix`, `perf`, `revert` or `docs`. `chore`, `ci`, `build`, `refactor`, `style` and `test` never release on their own.
