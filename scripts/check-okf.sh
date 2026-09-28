#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob dotglob

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "${script_dir}/.." && pwd)
okf_dir="${repo_root}/okf"

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

	# 2. archive must be healthy (extraction verifies every entry's CRC)
	if ! unzip -qq "${zip}" -d "${dest}"; then
		echo "${zip}: failed to unzip, archive may be corrupt"
		status=1
		return 0
	fi
	# mask macOS zip cruft anywhere in the tree; it's not part of the bundle
	find "${dest}" -depth \( -name '__MACOSX' -o -name '.DS_Store' \) -exec rm -rf {} +

	# 3. the archive holds a single root directory, without .okflintrc.json
	local entries=("${dest}"/*)
	if [[ ${#entries[@]} -ne 1 ]]; then
		echo "${zip}: expected exactly one top-level entry in the archive, found ${#entries[@]}"
		status=1
		return 0
	fi

	local root="${entries[0]}"
	if [[ ! -d "${root}" ]]; then
		echo "${zip}: top-level entry '${root##*/}' is not a directory"
		status=1
		return 0
	fi

	if [[ -f "${root}/.okflintrc.json" ]]; then
		echo "${zip}: root directory '${root##*/}' must not contain .okflintrc.json"
		status=1
		return 0
	fi

	# 4. the root index.md must declare okf_version "0.2"; okfctl validate
	# treats the declaration as optional, so it's enforced here
	if [[ ! -f "${root}/index.md" ]]; then
		echo "${zip}: root directory '${root##*/}' is missing index.md"
		status=1
		return 0
	fi
	if ! awk '
		NR == 1 { if ($0 != "---") exit; open = 1; next }
		$0 == "---" { closed = 1; exit }
		$0 == "okf_version: \"0.2\"" { found = 1 }
		END { exit !(open && closed && found) }
	' "${root}/index.md"; then
		echo "${zip}: root index.md must declare okf_version: \"0.2\""
		status=1
		return 0
	fi

	# 5. the bundle must conform to the OKF v0.2 spec floor
	if ! okfctl validate "${root}"; then
		echo "${zip}: failed okfctl validate"
		status=1
	fi
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
