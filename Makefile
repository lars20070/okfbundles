.PHONY: check-okf shellcheck
check-okf:
	@scripts/check-okf.sh

shellcheck:
	@shellcheck scripts/*.sh
