<!--
Title: one Conventional Commit header with one of this repository's scopes,
for example `feat(trainer): …`. It becomes the squash commit
on main, so write the line you want to read in `git log`.

Fill in every section. Write "n/a" rather than deleting one.
-->

## Summary

<!-- What this pull request does, in one or two sentences. -->

## Why

<!-- The problem or the motivation. For a fix: the bug, its root cause, and how to reproduce it. -->

Closes #

## Changes

-

## Verification

<!-- The commands you ran and what they showed, screenshots, or "CI only". -->

## Nets

<!-- crates/nnue-eval/tests/golden.rs pins how nets are checked against the engine; the trainer's settings and bullet pin decide what it makes. Pick one. For a perf change, also give the same command's speed before and after on the same machine. -->

- [ ] Nothing a net is trained or checked with changes: the golden test passes
      untouched, and the architecture, schedule, quantization and bullet pin are
      as before.
- [ ] It changes on purpose: the reason is under Why, any golden values are
      updated, and docs/nets.md says which net first uses it.

## Checklist

- [ ] The title is a Conventional Commit with one of this repository's scopes
- [ ] Every commit is one line, with only `Co-authored-by` trailers after it
- [ ] A breaking change is marked with `!` and explained under Why
- [ ] Docs are updated where behavior changed
