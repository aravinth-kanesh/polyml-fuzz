# Next Steps

## What Is Complete

### Infrastructure
- `scripts/build-polyml.sh`: automated instrumented build
- `scripts/build-harness.sh`: AFL++ harness compilation
- `scripts/verify-build.sh`: instrumentation verification
- `scripts/validate-seeds.sh`: seed corpus validation
- `scripts/ec2-setup.sh`: AWS Graviton setup

### Campaign Scripts
- `campaign/launch.sh`: phased campaign launcher (Phase 1 / Phase 2)
- `campaign/monitor.sh`: live coverage and crash dashboard
- `campaign/analytics.sh`: edges/hour logging and saturation detection
- `campaign/collect-crashes.sh`: crash collection and minimisation
- `campaign/triage.sh`: crash reproduction and classification
- `campaign/reproduce-crash.sh`: standalone crash reproduction
- `campaign/report.sh`: post-campaign summary report

### Seed Corpus (COMPLETE)
- **72 seeds** across 7 categories (target: 50+ exceeded)
- Subset A (lexer-focused): basic, operators, edge-cases, regression (~36 seeds)
- Subset B (parser-focused): stress, modules, datatypes (~36 seeds)

### Early Findings
- UBSan triggers documented in `results/early-findings/ub1/`
- Regression seeds created from findings

---

## Campaigns Completed (March 2026)

All production campaigns have been completed on AWS EC2 c7g.xlarge (Graviton 3, ARM64).

| Campaign | Duration | Seeds | Edges | Crashes | Coverage |
|----------|----------|-------|-------|---------|----------|
| Phase 1 (Subset A, lexer) | 72 hours | 35 | 2,014 | 3 (SIGKILL/OOM) | 28.57% libpolyml/ |
| Phase 2 (Subset B, parser) | 72 hours | 838 | 2,017 | 3 (SIGSEGV) | 28.55% libpolyml/ |
| Grammar-aware retry | 24 hours | 838 | 2,003 | 2 (SIGSEGV) | 28.59% libpolyml/ |

Coverage ceiling: **28.55–28.59%** across all three campaigns with different mutation strategies,
confirming the ceiling is structural (determined by frontend entry points) not mutation-dependent.

## Findings Summary

Four reliability findings were confirmed, all present in upstream master as of April 2026:

1. **ub1** — ARM64-specific UBSan overflow in `arm64.cpp:246` (pre-campaign). Fix validated locally, unmerged.
2. **Finding 2** — Lexer OOM on pathological float literal exponents (Phase 1). Fix validated locally, unmerged.
3. **Findings 3+4** — Three SIGSEGV crashes in module elaboration code (`TYPE_TREE.ML`, `TYPECHECK_PARSETREE.sml`), caused by a type safety defect in overloading resolution (Phase 2). Fix attempted but reverted (breaks bootstrap).

See `results/findings/README.md` for full details and reproducer commands.

## Future Work

If extending this project:
- **x86-64 comparison:** Run equivalent campaigns on x86-64 to quantify platform-specific vs platform-agnostic findings
- **Grammar-aware mutator:** `scripts/sml_mutator.py` is implemented but the retry showed no new fault classes; further tuning may help
- **C-reduce integration:** Automated crash minimisation to smallest reproducer (currently manual)
- **CI/CD integration:** Short campaigns on each upstream Poly/ML commit to detect regressions before release

---

**Status:** Campaigns complete — April 2026
