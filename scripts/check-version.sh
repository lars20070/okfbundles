#!/usr/bin/env bash
set -euo pipefail

# Check that VERSION agrees with the topmost release heading in CHANGELOG.md
# and, when given a release tag, that the tag names that same version.
#
#   usage: scripts/check-version.sh [vX.Y.Z]
#
# A release heading is a line starting `## [X.Y.Z]`; `## [Unreleased]` is not
# one. CRLF line endings are tolerated.

self=$(basename -- "${BASH_SOURCE[0]}")
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "${script_dir}/.." && pwd)
version_file="${repo_root}/VERSION"
changelog="${repo_root}/CHANGELOG.md"

die() {
	echo "${self}: $*" >&2
	exit 1
}

[[ $# -le 1 ]] || die "usage: ${self} [vX.Y.Z]"

[[ -f "${version_file}" ]] || die "VERSION is missing"
version=$(head -n 1 "${version_file}" | tr -d '\r')
[[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
	die "VERSION must hold X.Y.Z on its first line, found '${version}'"

[[ -f "${changelog}" ]] || die "CHANGELOG.md is missing"
changelog_text=$(tr -d '\r' <"${changelog}")
release_list=$(sed -nE 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/p' <<<"${changelog_text}")
[[ -n "${release_list}" ]] || die "CHANGELOG.md has no '## [X.Y.Z]' release heading"
mapfile -t releases <<<"${release_list}"

duplicates=$(sort <<<"${release_list}" | uniq -d)
[[ -z "${duplicates}" ]] ||
	die "CHANGELOG.md has more than one heading for: ${duplicates//$'\n'/, }"

[[ "${releases[0]}" == "${version}" ]] ||
	die "VERSION is ${version} but CHANGELOG.md's topmost release is ${releases[0]}"

if [[ $# -eq 1 ]]; then
	tag=$1
	[[ "${tag}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
		die "tag '${tag}' is not of the form vX.Y.Z"
	[[ "${tag#v}" == "${version}" ]] ||
		die "tag '${tag}' does not match VERSION ${version}"
	echo "${self}: tag ${tag}, VERSION and CHANGELOG.md agree on ${version}"
else
	echo "${self}: VERSION and CHANGELOG.md agree on ${version}"
fi
