# Agent Instructions

## Purpose

This repo is a simple collection of [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf)
(OKF) bundles — plain markdown-with-YAML-frontmatter wikis, vendor-neutral and
readable by humans and agents alike.

Each bundle lives under `okf/` as a `<name>.okf.zip` archive holding a single
root directory with the bundle tree inside it. Every non-reserved `.md` file
needs a frontmatter block with a non-empty `type`. `index.md` and `log.md` are
reserved and carry no frontmatter — except the bundle-root `index.md`, which
declares `okf_version: "0.2"`. `log.md`, if present, records changes as dated
entries (newest first, ISO 8601 dates).

Bundles target [OKF v0.2](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)
and are validated with [`okfctl validate`](https://github.com/cwest/okfctl),
which needs no per-bundle config. Bundles must not contain a `.okflintrc.json`
(the retired `okf-lint` config).

## Checks

CI (`.github/workflows/ci.yml`) runs these on every push/PR touching `okf/**`,
`scripts/**`, the `Makefile`, `VERSION`, `CHANGELOG.md`, or
`.github/workflows/**`:

- `make check-okf` (`scripts/check-okf.sh`, requires `okfctl`) verifies:
  - `okf/` contains only `*.okf.zip` files.
  - Each zip is a healthy archive that unzips cleanly.
  - Each zip holds exactly one root directory, with no `.okflintrc.json`.
  - The root `index.md` declares `okf_version: "0.2"` in its frontmatter.
    `okfctl validate` treats the declaration as optional, so the script
    enforces this repo invariant itself.
  - Each bundle passes `okfctl validate` (the OKF v0.2 conformance floor).

  CI installs `okfctl` v0.4.0 with Go 1.26.8; keep local versions in step.
- `make check-version` (`scripts/check-version.sh`) verifies that `VERSION`
  equals the topmost `## [X.Y.Z]` heading in `CHANGELOG.md`, and that no
  version has two headings.
- `make shellcheck` runs shellcheck over every script in `scripts/`.

Pushing a `vX.Y.Z` tag runs `.github/workflows/release.yml`: it reruns the
whole CI workflow, checks that the tag matches `VERSION`, and creates a GitHub
Release whose notes are that version's `CHANGELOG.md` section (extracted by
`scripts/release-notes.sh`). Re-runs leave an existing Release untouched.

`.DS_Store` and `__MACOSX` (macOS zip metadata) are masked throughout these
checks and tests — both in `okf/` itself and inside `*.okf.zip` archives, at
any depth. Their presence never fails a check.

## Skills

- `context7-docs` — fetch current library/framework docs before writing code
  against one.
- `debug-third-party` — check for a known upstream bug before working around
  an error that looks like it's from a dependency.
