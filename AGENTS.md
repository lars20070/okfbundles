# Agent Instructions

## Purpose

This repo is a simple collection of [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf)
(OKF) bundles — plain markdown-with-YAML-frontmatter wikis, vendor-neutral and
readable by humans and agents alike.

Each bundle lives under `okf/` as a `<name>.okf.zip` archive: a zipped
directory tree of `.md` files. A bundle's root `index.md` is the only file
allowed frontmatter (may declare `okf_version`); every other `.md` file needs
a parseable frontmatter block with a non-empty `type`. `log.md`, if present,
records changes as dated entries (newest first, ISO 8601 dates).

`okf/.okflintrc.json` inside each bundle defines the lint rules (titles,
descriptions, timestamps, valid links, log ordering, etc.) that bundle's
content should satisfy before it gets zipped back up.

## Checks

CI (`.github/workflows/ci.yml`) runs both of these on every push/PR touching
`okf/**`, `scripts/**`, or the `Makefile`:

- `make check-okf` (`scripts/check-okf.sh`, requires `pnpm`) verifies:
  - `okf/` contains only `*.okf.zip` files.
  - Each zip is a healthy archive that unzips cleanly.
  - Each zip's root directory contains a `.okflintrc.json`.
  - Each zip lints cleanly with `pnpm dlx @thisismydesign/okf-lint`.
- `make shellcheck` runs shellcheck over every script in `scripts/`.

## Skills

- `context7-docs` — fetch current library/framework docs before writing code
  against one.
- `debug-third-party` — check for a known upstream bug before working around
  an error that looks like it's from a dependency.
