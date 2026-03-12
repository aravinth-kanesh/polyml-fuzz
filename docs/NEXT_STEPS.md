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

## Campaign Plan

### Step 1: AWS Graviton Setup

```bash
# Launch c7g.xlarge (ARM64 Ubuntu 22.04)
./scripts/ec2-setup.sh
./scripts/build-polyml.sh
./scripts/build-harness.sh
./scripts/verify-build.sh
./scripts/validate-seeds.sh
```

### Step 2: Phase 1 Campaign (3-4 days, Subset A)

```bash
tmux new -s phase1

# Launch Phase 1 (3 days = 259200 seconds)
./campaign/launch.sh --phase 1 --duration 259200 --instances 4

# In a second pane: track saturation
./campaign/analytics.sh phase1-lexer-YYYYMMDD-HHMMSS

# In a third pane: live dashboard
watch -n 30 ./campaign/monitor.sh phase1-lexer-YYYYMMDD-HHMMSS
```

Stop early if `analytics.sh` reports saturation (< 10 new edges/hour for 3 consecutive hours).

### Step 3: Post-Phase 1 Analysis

```bash
./campaign/collect-crashes.sh phase1-lexer-YYYYMMDD-HHMMSS
./campaign/triage.sh phase1-lexer-YYYYMMDD-HHMMSS
./campaign/report.sh phase1-lexer-YYYYMMDD-HHMMSS
```

### Step 4: Phase 2 Campaign (3-4 days, Subset B)

Only run if Phase 1 was productive (non-trivial crashes or coverage).

```bash
./campaign/launch.sh --phase 2 --duration 259200 --instances 4
```

---

## What to Look For

### Success indicators
- Exec/sec > 1000 (ideally 2000+ on Graviton)
- Coverage growth in first 24-48 hours
- Crashes discovered (any type is useful)
- Saturation detected (confirms thorough exploration)

### Saturation is the goal
Coverage saturation (tracked by `analytics.sh`) tells you when the campaign has exhausted reachable edges. This is the key measurement for your evaluation chapter.

---

## Budget (~$100 AWS credit)

| Instance | vCPUs | $/hour | 3+3 days cost |
|----------|-------|--------|---------------|
| c7g.xlarge | 4 | ~$0.14 | ~$20 |
| c7g.2xlarge | 8 | ~$0.29 | ~$42 |

**Recommended: AWS EC2 free tier ARM64 instance.** 2 fuzzer instances suited to low-spec free tier hardware.

---

## For the Evaluation Chapter (Chapter 5)

After the campaign, document:
1. **Experimental setup:** Instance type, instances, seed subset, duration per phase
2. **Coverage results:** Edges found, saturation time, edges/hour plot
3. **Fault discovery:** Crashes found, classified by type (UBSan/ASan/signal)
4. **Throughput:** Exec/sec achieved on ARM64 Graviton
5. **Pre-campaign findings:** UBSan bug in `arm64.cpp:246` (mark as pre-campaign)
6. **Discussion:** What the coverage and crashes say about Poly/ML reliability on ARM64

---

**Status:** Ready for AWS deployment
