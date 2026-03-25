# Starburst data products — run from this directory: make -C .agents/skills/starburst-data-products <target>
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPTS := $(MAKEFILE_DIR)scripts

.PHONY: help all setup create-domain init write-sample lint import export compare write-modified import-modified import-fail publish cleanup

help:
	@echo "Starburst data products — step scripts"
	@echo ""
	@echo "  make all                 # setup through import-modified (sample flow)"
	@echo "  make setup|create-domain|init|write-sample|lint|import|export|compare"
	@echo "  make write-modified|import-modified|import-fail"
	@echo "  make publish PRODUCT_ID=<id>"
	@echo "  make cleanup PRODUCT_ID=<id> DOMAIN_ID=<id>"
	@echo ""
	@echo "Scripts live in: $(SCRIPTS)"

all: setup create-domain init write-sample lint import export compare write-modified import-modified

setup:
	$(SCRIPTS)/setup.sh

create-domain:
	$(SCRIPTS)/create-domain.sh

init:
	$(SCRIPTS)/init.sh

write-sample:
	$(SCRIPTS)/write-sample-yaml.sh

lint:
	$(SCRIPTS)/lint.sh

import:
	$(SCRIPTS)/import.sh

export:
	$(SCRIPTS)/export.sh

compare:
	$(SCRIPTS)/compare.sh

write-modified:
	$(SCRIPTS)/write-modified-yaml.sh

import-modified:
	$(SCRIPTS)/import-modified.sh

import-fail:
	$(SCRIPTS)/import.sh --on-duplicate FAIL

publish:
	@test -n "$(PRODUCT_ID)" || (echo "Usage: make publish PRODUCT_ID=<uuid>"; exit 1)
	$(SCRIPTS)/publish.sh $(PRODUCT_ID)

cleanup:
	@test -n "$(PRODUCT_ID)" || (echo "Usage: make cleanup PRODUCT_ID=<uuid> DOMAIN_ID=<uuid>"; exit 1)
	@test -n "$(DOMAIN_ID)" || (echo "Usage: make cleanup PRODUCT_ID=<uuid> DOMAIN_ID=<uuid>"; exit 1)
	$(SCRIPTS)/cleanup.sh $(PRODUCT_ID) $(DOMAIN_ID)
