# Production Campaign Findings

This directory contains the artefacts from the three production fuzzing campaigns run on
AWS EC2 c7g.xlarge (Graviton 3, ARM64, Ubuntu 22.04) in March 2026.

## Campaigns

| Directory | Campaign | Duration | Description |
|-----------|----------|----------|-------------|
| `phase1/` | phase1-lexer-20260316-124325 | 72 hours | Phase 1: Subset A (35 seeds, lexer focus) |
| `phase2/` | phase2-parser-20260319-131212 | 72 hours | Phase 2: Subset B + evolved corpus (838 seeds, parser focus) |
| `grammar-retry/` | phase2-parser-20260322-192228 | 24 hours | Grammar-aware mutator retry (Phase 2 corpus, sml_mutator.py on fuzzer03/04) |

## Directory Structure (per campaign)

```
<campaign>/
├── REPORT.md              -- Post-campaign summary (edges, crashes, hangs, coverage)
├── campaign.meta          -- Raw campaign parameters (key=value)
├── collected-crashes/     -- Deduplicated, minimised crash inputs
│   └── minimised/         -- afl-tmin minimised versions
├── triaged/               -- Per-crash triage reports (stack traces, reproduction commands)
├── collected-hangs/       -- Deduplicated hang inputs (SML files that cause timeouts)
├── triaged-hangs/         -- Per-hang triage summaries (confirmed/not-reproduced)
├── coverage/
│   └── coverage_report.txt -- LLVM per-file region/line coverage table
└── analytics/             -- edges_over_time.csv and saturation.log (Phase 1 and 2 only)
```

## Key Results

### Phase 1
- 2,014 AFL++ edges; saturation at ~8 hours
- 3 crashes: all SIGKILL (memory exhaustion via ASan overhead)
  - Crash 1: infinite recursion (mutated factorial, wrong base case)
  - Crashes 2+3: pathological float literal exponent (lexer OOM, genuine finding)
- 34 confirmed hangs (of 62 unique collected)
- LLVM coverage: 28.57% libpolyml/, 39.75% arm64.cpp

### Phase 2
- 2,017 AFL++ edges; saturation at ~4 hours
- 3 crashes: all SIGSEGV (genuine module elaboration faults)
  - Crashes 1+2: nested structure with corrupted identifiers
  - Crash 3: integer literal pattern in structure value binding
- 14 confirmed hangs (of 98 unique collected)
- LLVM coverage: 28.55% libpolyml/, 37.89% arm64.cpp

### Grammar-Aware Retry
- 2,003 AFL++ edges (same ceiling as Phase 1 and 2)
- 2 crashes: SIGSEGV (same module elaboration fault class as Phase 2)
- 7 confirmed hangs (of 21 unique collected)
- LLVM coverage: 28.59% libpolyml/, 39.75% arm64.cpp
- Confirms the coverage ceiling is structural and mutation-strategy-independent

## Pre-Campaign Findings

See `../early-findings/ub1/` for the pre-campaign UBSan finding:
- `libpolyml/arm64.cpp:246`: unsigned integer overflow, triggered by valid SML programs
- ARM64-specific; not present on x86-64
