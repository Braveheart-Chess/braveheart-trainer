<!--
PR title must be a valid Conventional Commit, e.g. `feat(scope): add something`.
Squash merges use the title as the commit message.
-->

## Summary

<!-- One or two sentences on what this PR does. -->

## Motivation and context

<!-- Why is this change needed? Link issues, runs or the docs/nets.md entry. -->

## What changed

<!-- Bullet the changes. Call out anything that changes the architecture, the schedule, the quantization, the file format, training.json or a workflow's inputs. -->

-

## How it was verified

<!-- e.g. cargo fmt/clippy/test in both workspaces, the diagram check, a local training run, a workflow run (link it). -->

-

## Nets

<!-- crates/nnue-eval/tests/golden.rs pins how nets are checked against the engine; the trainer's settings and bullet pin decide what it makes. Pick one. -->

- [ ] Nothing a net is trained or checked with changes: the golden test passes
      untouched, and the architecture, schedule, quantization and bullet pin are
      as before.
- [ ] It changes on purpose: the reason is above, any golden values are
      updated, and docs/nets.md says which net first uses it.

## Checklist

- [ ] PR title is a valid Conventional Commit (`feat`)
- [ ] Every commit is a single line (only `Co-authored-by` trailers may follow)
- [ ] Every run this PR made is recorded in docs/ (see AGENTS.md)
- [ ] Docs updated (README, docs/, CONTRIBUTING, AGENTS) where behaviour changed
