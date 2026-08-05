.PHONY: check-okf
check-okf:
	@bad=$$(find okf -mindepth 1 -maxdepth 1 ! -name '*.okf.zip'); \
	if [ -n "$$bad" ]; then \
		echo "okf/ must contain only *.okf.zip files, found:"; \
		echo "$$bad"; \
		exit 1; \
	fi
