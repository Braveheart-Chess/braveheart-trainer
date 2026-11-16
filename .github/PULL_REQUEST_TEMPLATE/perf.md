<!--
PR title must be a valid Conventional Commit, e.g. `perf(scope): speed up something`.
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

## Speed

<!-- The same command before and after on the same machine; the nets must be unchanged. -->

- Before: `<seconds per superbatch, or positions a second>`
- After: `<seconds per superbatch, or positions a second>`

## Nets

<!-- A perf PR changes nothing a net is trained or checked with. -->

- [ ] The golden test passes untouched, and the architecture, schedule,
      quantization and bullet pin are as before.

## Checklist

- [ ] PR title is a valid Conventional Commit (`perf`)
- [ ] Every commit is a single line (only `Co-authored-by` trailers may follow)
- [ ] Every run this PR made is recorded in docs/ (see AGENTS.md)
- [ ] Docs updated (README, docs/, CONTRIBUTING, AGENTS) where behaviour changed
