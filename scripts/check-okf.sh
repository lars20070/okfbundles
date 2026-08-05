#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "${script_dir}/.." && pwd)
okf_dir="${repo_root}/okf"

# clean up extraction temp dirs on exit
tmp_dirs=()
# shellcheck disable=SC2329 # invoked indirectly via trap below
cleanup() {
	for d in "${tmp_dirs[@]:-}"; do
		[[ -n "${d}" ]] && rm -rf "${d}"
	done
}
trap cleanup EXIT

if ! command -v pnpm >/dev/null 2>&1; then
	echo "pnpm is required (npm install -g pnpm) to lint OKF bundles" >&2
	exit 1
fi

# 1. okf/ must contain only *.okf.zip files
bad=$(find "${okf_dir}" -mindepth 1 -maxdepth 1 ! -name '*.okf.zip')
if [[ -n "${bad}" ]]; then
	echo "okf/ must contain only *.okf.zip files, found:"
	echo "${bad}"
	exit 1
fi

status=0
shopt -s nullglob
for zip in "${okf_dir}"/*.okf.zip; do
	# 2. archive must be healthy (unzippable)
	if ! unzip -tq "${zip}" >/dev/null; then
		echo "${zip}: failed integrity check, archive may be corrupt"
		status=1
		continue
	fi

	tmp=$(mktemp -d)
	tmp_dirs+=("${tmp}")

	if ! unzip -qq "${zip}" -d "${tmp}"; then
		echo "${zip}: unzip failed despite passing integrity check"
		status=1
		continue
	fi

	# 3. the archive's root directory must contain .okflintrc.json
	roots=()
	while IFS= read -r d; do
		roots+=("${d}")
	done < <(find "${tmp}" -mindepth 1 -maxdepth 1 -type d ! -name '__MACOSX' || true)

	if [[ "${#roots[@]}" -ne 1 ]]; then
		echo "${zip}: expected exactly one root directory in the archive, found ${#roots[@]}"
		status=1
	elif [[ ! -f "${roots[0]}/.okflintrc.json" ]]; then
		echo "${zip}: root directory '$(basename "${roots[0]}")' is missing .okflintrc.json"
		status=1
	# 4. the bundle must lint cleanly with okf-lint
	elif ! pnpm dlx @thisismydesign/okf-lint "${roots[0]}"; then
		echo "${zip}: failed okf-lint"
		status=1
	fi
done

exit "${status}"
