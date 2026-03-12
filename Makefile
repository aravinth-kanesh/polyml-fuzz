##
## Poly/ML Fuzzing Framework
##
## Usage:
##   make smoke                                         # 30-min validation run
##   make phase1                                        # full Phase 1 campaign (3 days)
##   make phase2 EVOLVED=phase1-lexer-YYYYMMDD-HHMMSS  # Phase 2 with evolved seeds
##   make monitor  CAMPAIGN=phase1-lexer-YYYYMMDD-HHMMSS
##   make report   CAMPAIGN=phase1-lexer-YYYYMMDD-HHMMSS
##   make status                                        # list recent campaigns
##
## Override defaults:
##   make phase1 DURATION=86400 INSTANCES=4
##

SHELL     := /bin/bash
DURATION  ?= 259200
INSTANCES ?= 2
CAMPAIGN  ?=
EVOLVED   ?=

.PHONY: help smoke phase1 phase2 monitor report analyse status setup verify

help:
	@echo "Poly/ML Fuzzing Framework"
	@echo ""
	@echo "  make smoke                                        30-min validation run"
	@echo "  make phase1                                       full Phase 1 campaign (3 days)"
	@echo "  make phase2 EVOLVED=phase1-lexer-YYYYMMDD-HHMMSS Phase 2 with evolved seeds"
	@echo "  make monitor  CAMPAIGN=<name>                     live status dashboard"
	@echo "  make report   CAMPAIGN=<name>                     post-campaign analysis"
	@echo "  make status                                       list recent campaigns"
	@echo "  make setup                                        build instrumented Poly/ML"
	@echo "  make verify                                       verify build and seeds"
	@echo ""
	@echo "Override duration/instances:"
	@echo "  make phase1 DURATION=86400 INSTANCES=4"

smoke:
	./campaign/start.sh --phase 1 --duration 1800 --instances 2

phase1:
	./campaign/start.sh --phase 1 --duration $(DURATION) --instances $(INSTANCES)

phase2:
	@if [ -z "$(EVOLVED)" ]; then \
		echo "Error: EVOLVED is required for phase2."; \
		echo "Usage: make phase2 EVOLVED=phase1-lexer-YYYYMMDD-HHMMSS"; \
		echo ""; \
		echo "Recent Phase 1 campaigns:"; \
		ls -t results/ 2>/dev/null | grep "phase1" | head -5 || echo "  (none)"; \
		exit 1; \
	fi
	./campaign/start.sh --phase 2 \
		--duration $(DURATION) \
		--instances $(INSTANCES) \
		--evolved $(EVOLVED)

monitor:
	@if [ -z "$(CAMPAIGN)" ]; then \
		echo "Usage: make monitor CAMPAIGN=<campaign-name>"; \
		echo ""; \
		echo "Recent campaigns:"; \
		ls -t results/ 2>/dev/null | grep -v "early-findings\|coverage" | head -10 || echo "  (none)"; \
		exit 1; \
	fi
	watch -c -n 30 ./campaign/monitor.sh $(CAMPAIGN)

report: analyse

analyse:
	@if [ -z "$(CAMPAIGN)" ]; then \
		echo "Usage: make report CAMPAIGN=<campaign-name>"; \
		echo ""; \
		echo "Recent campaigns:"; \
		ls -t results/ 2>/dev/null | grep -v "early-findings\|coverage" | head -10 || echo "  (none)"; \
		exit 1; \
	fi
	./campaign/analyse.sh $(CAMPAIGN)

status:
	@echo "Recent campaigns:"
	@ls -t results/ 2>/dev/null | grep -v "early-findings\|coverage" | head -10 || echo "  (none)"
	@echo ""
	@echo "Active fuzzers: $$(pgrep -c afl-fuzz 2>/dev/null || echo 0)"

setup:
	./scripts/build-polyml.sh

verify:
	./scripts/verify-build.sh
	./scripts/validate-seeds.sh
