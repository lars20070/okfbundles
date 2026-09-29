#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob dotglob

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "${script_dir}/.." && pwd)
okf_dir="${repo_root}/okf"

# OKF spec version every bundle must declare. Bump it together with the okfctl
# pin in CI, since okfctl validates against the rules of one spec version.
okf_version="0.2"

work_dir=$(mktemp -d)
trap 'rm -rf "${work_dir}"' EXIT

if ! command -v okfctl >/dev/null 2>&1; then
	echo "okfctl is required (https://github.com/cwest/okfctl) to validate OKF bundles" >&2
	exit 1
fi

status=0

# Checks 2 to 5 for one bundle. Prints its own diagnostics and records problems in
# `status` rather than returning non-zero, so it can be called as a plain
# command: that keeps `set -e` active inside it, and lets every bundle be
# checked even after one fails.
check_bundle() {
	local zip=$1
	local dest="${work_dir}/${zip##*/}"
	local name=${zip##*/}
	name=${name%.okf.zip}

	# 2. archive must be healthy (extraction verifies every entry's CRC)
	if ! unzip -qq "${zip}" -d "${dest}"; then
		echo "failed to unzip, archive may be corrupt (${name})"
		status=1
		return 0
	fi
	# mask macOS zip cruft anywhere in the tree; it's not part of the bundle
	find "${dest}" -depth \( -name '__MACOSX' -o -name '.DS_Store' \) -exec rm -rf {} +

	# 3. the archive holds a single root directory, without .okflintrc.json
	local entries=("${dest}"/*)
	if [[ ${#entries[@]} -ne 1 ]]; then
		echo "expected exactly one top-level entry in the archive, found ${#entries[@]} (${name})"
		status=1
		return 0
	fi

	local root="${entries[0]}"
	if [[ ! -d "${root}" ]]; then
		echo "top-level entry '${root##*/}' is not a directory (${name})"
		status=1
		return 0
	fi

	if [[ -f "${root}/.okflintrc.json" ]]; then
		echo "root directory '${root##*/}' must not contain .okflintrc.json (${name})"
		status=1
		return 0
	fi

	# 4. the root index.md must declare okf_version "${okf_version}"; okfctl
	# validate treats the declaration as optional, so it's enforced here
	if [[ ! -f "${root}/index.md" ]]; then
		echo "root directory '${root##*/}' is missing index.md (${name})"
		status=1
		return 0
	fi
	if ! awk -v want="okf_version: \"${okf_version}\"" '
		NR == 1 { if ($0 != "---") exit; open = 1; next }
		$0 == "---" { closed = 1; exit }
		$0 == want { found = 1 }
		END { exit !(open && closed && found) }
	' "${root}/index.md"; then
		echo "root index.md must declare okf_version: \"${okf_version}\" (${name})"
		status=1
		return 0
	fi

	# 5. the bundle must conform to the OKF spec floor. --no-ignore walks
	# the whole tree: okfctl otherwise skips directories such as vendor/, build/
	# or env/, but in a distributed bundle those hold content too
	local output
	if ! output=$(okfctl validate --no-ignore "${root}" 2>&1); then
		[[ -n "${output}" ]] && echo "${output}"
		echo "failed okfctl validate (${name})"
		status=1
		return 0
	fi
	# replace okfctl's generic OK line with one naming the bundle, keeping any
	# other output (e.g. advisory warnings)
	output=$(grep -v '^OK: ' <<<"${output}" || true)
	[[ -n "${output}" ]] && echo "${output}"
	echo "OK, conforms to OKF v${okf_version} (${name})"
}

# 1. okf/ folder must contain only *.okf.zip files (macOS metadata is masked)
bad=$(find "${okf_dir}" -mindepth 1 -maxdepth 1 \
	! -name '*.okf.zip' ! -name '__MACOSX' ! -name '.DS_Store')
if [[ -n "${bad}" ]]; then
	echo "okf/ must contain only *.okf.zip files, found:"
	echo "${bad}"
	exit 1
fi

for zip in "${okf_dir}"/*.okf.zip; do
	check_bundle "${zip}"
done

exit "${status}"
