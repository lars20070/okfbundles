# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- `make check-okf` now runs `okfctl validate --no-ignore`, so every Markdown
  file in a bundle is checked. By default `okfctl` skips directories named
  like vendored or build output (`vendor`, `build`, `dist`, `env`, …), which
  let non-conformant files there pass.

## [0.1.0] - 2026-09-29

### Added

- Bundle `TheHoundOfTheBaskervilles`: a wiki of *The Hound of the
  Baskervilles* covering its stories, characters, locations, events, factions,
  items, arcs, relationships and open questions.
- Bundle `GoogleStyleGuide-abridged`: a condensed edition of the Google
  developer documentation style guide. Its directory listings use
  bundle-absolute links.
- `make check-okf` now requires the bundle-root `index.md` to declare
  `okf_version: "0.2"` in its frontmatter. `okfctl validate` treats the
  declaration as optional, so the check script enforces it.
- Release workflow: pushing a `vX.Y.Z` tag reruns CI and creates a GitHub
  Release whose notes are the matching `CHANGELOG.md` section.
- `make check-version`, run in CI, requires `VERSION` to match the topmost
  release heading in `CHANGELOG.md`.

### Changed

- All bundles now target [OKF v0.2](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)
  instead of v0.1. Each bundle-root `index.md` declares `okf_version: "0.2"`;
  bundle content is otherwise unchanged. Legacy v0.1 `timestamp` fields and
  `# Citations` sections are kept, as v0.2 still accepts them.
- Bundles are validated with [`okfctl validate`](https://github.com/cwest/okfctl)
  instead of [`okf-lint`](https://github.com/thisismydesign/okf-lint).
  `make check-okf` now needs `okfctl` rather than `pnpm`.
- CI installs `okfctl` v0.4.0 with Go 1.26.8 via `actions/setup-go` v7.0.0
  (pinned by commit), replacing the global `pnpm` install.
- `README.md` and `AGENTS.md` describe the `okfctl`-based workflow and the
  OKF v0.2 requirements.

### Removed

- The per-bundle `.okflintrc.json` lint config. `make check-okf` now rejects
  bundles that contain one.
- Checks previously enforced through `okf-lint` rules and not covered by the
  OKF v0.2 conformance floor: required titles, descriptions and timestamps,
  timestamp format, tag types, link validity, absolute-link style, log
  presence and log date order.
