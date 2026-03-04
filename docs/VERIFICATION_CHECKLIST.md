# Repository Verification Checklist

## Repository Organisation

- [x] Clean directory structure
- [x] No unnecessary files
- [x] Proper `.gitignore` configured (build artefacts, logs, phase outputs)
- [x] All scripts executable

## Infrastructure

### Build Scripts
- [x] `scripts/build-polyml.sh`: automated instrumented build
- [x] `scripts/build-harness.sh`: harness compilation
- [x] `scripts/verify-build.sh`: instrumentation verification
- [x] `scripts/validate-seeds.sh`: seed corpus validation
- [x] `scripts/ec2-setup.sh`: AWS Graviton setup

### Campaign Scripts
- [x] `campaign/launch.sh`: phased campaign launcher (Phase 1 / Phase 2, configurable duration)
- [x] `campaign/monitor.sh`: live coverage/crash dashboard with edges/hour
- [x] `campaign/analytics.sh`: saturation tracking (edges/hour to CSV)
- [x] `campaign/collect-crashes.sh`: crash collection and minimisation
- [x] `campaign/triage.sh`: crash reproduction and classification
- [x] `campaign/reproduce-crash.sh`: standalone crash reproduction
- [x] `campaign/report.sh`: post-campaign Markdown summary report

### Seed Corpus (COMPLETE)
- [x] `seeds/basic/` (12 seeds)
- [x] `seeds/datatypes/` (11 seeds)
- [x] `seeds/modules/` (12 seeds)
- [x] `seeds/operators/` (11 seeds)
- [x] `seeds/stress/` (13 seeds)
- [x] `seeds/edge-cases/` (8 seeds)
- [x] `seeds/regression/` (2 seeds)
- [x] `seeds/README.md`

## Documentation

- [x] `README.md` -- Setup guide and campaign strategy
- [x] `docs/NEXT_STEPS.md` -- Campaign roadmap
- [x] `docs/PROJECT_ALIGNMENT.md` -- Brief/report alignment analysis
- [x] `docs/SEED_CORPUS_COMPLETE.md` -- Seed corpus documentation
- [x] `docs/VERIFICATION_CHECKLIST.md` -- This file

## Early Findings

- [x] `results/early-findings/ub1/` -- UBSan bug in `arm64.cpp:246`
- [x] Documented as pre-campaign finding
- [x] Regression seeds in `seeds/regression/`

## Known Bug in Harness (Fixed)

The original `campaign/launch.sh` passed `@@` to the harness, but the harness reads from stdin. This has been corrected and the updated script passes no `@@`.

## Campaign Strategy Alignment (Updated per Supervisor Feedback)

- [x] Changed from single 2-week run to two 3-4 day phased campaigns
- [x] Phase 1: Subset A corpus (lexer-focused seeds)
- [x] Phase 2: Subset B corpus (parser-focused seeds)
- [x] Saturation tracking via `analytics.sh` (edges/hour -> CSV)
- [x] Stop criteria defined (< 10 edges/hour for 3 consecutive hours)
- [x] AFL++ mutators documented in README
- [x] UC2 (crash reproduction) fully automated via `reproduce-crash.sh`
- [x] Pre-campaign findings labelled separately in `results/early-findings/`

## Statistics

- **Total Seeds:** 69 (target: 50+ exceeded)
- **Campaign Scripts:** 7
- **Build/Validation Scripts:** 5
- **Documentation:** 5 markdown files

---

**Date Verified:** February 2026
