#!/usr/bin/env bash
set -euo pipefail

# Print the body of one release's section of CHANGELOG.md, for use as GitHub
# Release notes. The heading itself is left out: GitHub shows the tag as the
# release title.
#
#   usage: scripts/release-notes.sh X.Y.Z

self=$(basename -- "${BASH_SOURCE[0]}")
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "${script_dir}/.." && pwd)
changelog="${repo_root}/CHANGELOG.md"

die() {
	echo "${self}: $*" >&2
	exit 1
}

[[ $# -eq 1 ]] || die "usage: ${self} X.Y.Z"
version=$1
[[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
	die "'${version}' is not of the form X.Y.Z"
[[ -f "${changelog}" ]] || die "CHANGELOG.md is missing"

# Escaped so the dots in 0.1.0 can't match any character.
heading="^## \\[${version//./\\.}\\]"

count=$(tr -d '\r' <"${changelog}" | grep -cE "${heading}" || true)
[[ "${count}" -ge 1 ]] || die "CHANGELOG.md has no '## [${version}]' heading"
[[ "${count}" -eq 1 ]] || die "CHANGELOG.md has ${count} '## [${version}]' headings"

# The pattern goes through ENVIRON, not `awk -v`, which would re-interpret its
# backslashes. Leading blank lines are dropped.
notes=$(tr -d '\r' <"${changelog}" |
	HEADING="${heading}" awk '
		$0 ~ ENVIRON["HEADING"] { f = 1; next }
		/^## \[/ { f = 0 }
		f
	' | sed '/[^[:space:]]/,$!d')

[[ -n "${notes}" ]] || die "CHANGELOG.md has no content under '## [${version}]'"

printf '%s\n' "${notes}"
