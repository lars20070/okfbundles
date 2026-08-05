#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob dotglob

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "${script_dir}/.." && pwd)
okf_dir="${repo_root}/okf"

work_dir=$(mktemp -d)
trap 'rm -rf "${work_dir}"' EXIT

if ! command -v pnpm >/dev/null 2>&1; then
	echo "pnpm is required (npm install -g pnpm) to lint OKF bundles" >&2
	exit 1
fi

status=0

# Checks 2 to 4 for one bundle. Prints its own diagnostics and records problems in
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

	# 3. the archive's single root directory must contain .okflintrc.json
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

	if [[ ! -f "${root}/.okflintrc.json" ]]; then
		echo "${zip}: root directory '${root##*/}' is missing .okflintrc.json"
		status=1
		return 0
	fi

	# 4. the bundle must lint cleanly with okf-lint
	if ! pnpm dlx @thisismydesign/okf-lint "${root}"; then
		echo "${zip}: failed okf-lint"
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
