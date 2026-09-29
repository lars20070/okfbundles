.PHONY: check-okf check-version shellcheck
check-okf:
	@scripts/check-okf.sh

check-version:
	@scripts/check-version.sh

shellcheck:
	@shellcheck scripts/*.sh
