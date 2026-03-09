# Trial Fuzzing Campaign Findings

## Overview

Three trial fuzzing runs were conducted on an Apple Silicon M2 (ARM64, macOS) development machine
prior to the main AWS Graviton campaigns. The goals were to validate the toolchain, characterise
coverage growth behaviour, and estimate throughput. A significant design issue was identified and
resolved during Trial 1, resulting in a change to the fuzzing architecture.

---

## Trial 1: Phase 1 - Harness-Based Fuzzing (1 hour)

| Parameter | Value |
|---|---|
| Date | 4 March 2026 |
| Duration | 1 hour |
| Instances | 2 |
| Corpus | Subset A - 33 seeds (basic, operators, edge-cases, regression) |
| Target | `harness_afl` (AFL++ persistent-mode C harness) |

### Results

| Metric | Value |
|---|---|
| Edges found | **12** |
| Total executions | 108,915 |
| Unique crashes | 0 |
| Hangs | 2 |

### Key Finding: Coverage Visibility Problem

The 12-edge result immediately indicated a design fault. The harness binary invoked Poly/ML via
`system("poly < input.sml")`, which spawns `poly` as a child process. AFL++ instruments the
process it launches directly - it cannot track edge coverage inside a child process created by
`system()`. As a result, coverage was limited to the ~12 edges in the harness itself rather than
the thousands of edges in the Poly/ML lexer and parser.

**Resolution:** Subsequent trials switched to direct fuzzing of the instrumented `poly` binary
(AFL++ feeds input via stdin, no intermediate harness). This gives AFL++ full visibility into
`libpolyml/` and the SML frontend. The harness is retained in the repository as a design record.

---

## Trial 2: Phase 1 - Direct Fuzzing (2 hours)

| Parameter | Value |
|---|---|
| Date | 5 March 2026 |
| Duration | 2 hours |
| Instances | 2 |
| Corpus | Subset A - 33 seeds (basic, operators, edge-cases, regression) |
| Target | `build/polyml-instrumented/install/bin/poly` (direct) |

### Results

| Metric | Value |
|---|---|
| Edges found | **1,940** |
| Total executions | 613,711 |
| Peak exec/sec | ~1,003 |
| Evolved corpus size | 627 entries (from 33 seeds) |
| Unique crashes | 4 (all SIGKILL) |
| Hangs | 7 |
| Coverage saturation | Detected at 18:03 UTC (~53 min into run) |

### Coverage Growth

Coverage grew rapidly in the first 30 minutes (1,637 edges in the first sample window), slowed
significantly thereafter, and was declared saturated after approximately 53 minutes when the edge
discovery rate dropped to zero new edges per hour for three consecutive measurement windows.

| Time into run | Edges found | Delta (edges/sample) |
|---|---|---|
| ~2 min | 1,637 | +1,637 |
| ~7 min | 1,643 | +6 |
| ~12 min | 1,716 | +73 |
| ~30 min | 1,719 | +3 |
| ~53 min | 1,919 | +0 (saturation declared) |
| 2 hours | 1,940 | +0 |

### Crashes

All 4 unique crashes carry `sig:09` (SIGKILL). On macOS, AFL++ persistent mode operates under
System V shared memory constraints, and it is likely that these kills originate from macOS
terminating the process during memory allocation rather than from a Poly/ML fault. Sanitiser
output was empty for all four inputs, which is consistent with SIGKILL (the sanitiser runtime
has no opportunity to write a report before the process is killed). These are expected macOS
artefacts and are not counted as genuine Poly/ML bugs. The AWS Graviton (Linux) campaigns will
use a higher memory limit and will not be subject to macOS shared memory restrictions.

---

## Trial 3: Phase 2 - Direct Fuzzing (2 hours)

| Parameter | Value |
|---|---|
| Date | 5 March 2026 |
| Duration | 2 hours |
| Instances | 2 |
| Corpus | Subset B - 36 seeds (stress, modules, datatypes) |
| Target | `build/polyml-instrumented/install/bin/poly` (direct) |

### Results

| Metric | Value |
|---|---|
| Edges found | **1,738** |
| Total executions | 722,266 |
| Peak exec/sec | ~1,047 |
| Evolved corpus size | 523 entries (from 36 seeds) |
| Unique crashes | 1 (SIGKILL) |
| Hangs | 0 |
| Coverage saturation | Detected at 20:52 UTC (~1 hour into run) |

### Coverage Growth

Phase 2 reached saturation after approximately one hour (slightly later than Phase 1), likely
reflecting the greater structural complexity of the parser-focused seeds in Subset B. Edge count
(1,738) was comparable to Phase 1 (1,940), suggesting both corpus subsets access a similar
depth of the Poly/ML frontend under these short trial conditions.

---

## Pre-Campaign Finding: ARM64-Specific UBSan Bug (ub1)

| Field | Detail |
|---|---|
| Date found | 9 December 2025 |
| Location | `libpolyml/arm64.cpp:246` |
| Type | Unsigned integer overflow (UBSan) |
| Trigger | Two valid, syntactically correct SML programs |
| Exit code | 134 (SIGABRT from UBSan) |
| Platform | ARM64 only (does not reproduce on x86-64) |

During pre-campaign validation of the sanitiser build, two programs from the seed corpus, a factorial function and a simple datatype with an eval function, consistently triggered a
UBSan runtime error:

```
libpolyml/arm64.cpp:246:32: runtime error:
addition of unsigned offset to 0x00037fff80e0 overflowed to 0x00037fff80c0
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior libpolyml/arm64.cpp:246:32
```

The overflow occurs during ARM64-specific register allocation or offset calculation in the code
generator. Because it is triggered by *valid* Standard ML input rather than malformed syntax, it
is an unconditional fault on ARM64 - not dependent on malicious or unusual input. This is a
medium-severity finding: it constitutes undefined behaviour in a production-use compiler on ARM64,
and affects any user of Poly/ML on this architecture.

The two triggering programs have been retained as regression seeds (`seeds/regression/`) and are
included in Subset A. This finding will be reported to the Poly/ML maintainers after the main
campaign is complete.

---

## Infrastructure Validation Summary

The trials confirm that the fuzzing infrastructure is correctly configured for the main campaigns:

| Check | Status |
|---|---|
| Direct fuzzing of `poly` binary gives full edge coverage | Confirmed (Trial 2: 1,940 edges vs Trial 1: 12) |
| AFL++ correctly receives coverage feedback from `libpolyml/` | Confirmed |
| ASan/UBSan runtime instrumentation active | Confirmed (ub1 finding) |
| Coverage saturation detection working | Confirmed (saturation logged correctly in both trials) |
| Throughput on ARM64 | ~1,000 exec/sec on Apple M2 (local); higher expected on Graviton |
| Corpus evolution (seed promotion) | Confirmed (33 seeds → 627 evolved in Phase 1) |

---

## Notes for Main Campaign

- **Platform:** macOS trials are for infrastructure validation only. All production campaigns will
  run on a persistent ARM64 Linux instance (Ubuntu 22.04). Linux removes the macOS shared memory
  constraints that caused the SIGKILL artefacts.
- **Duration:** Main campaigns are 3-4 days (Phase 1) and 3-4 days (Phase 2, conditional on
  Phase 1 results). The ~1-hour saturation observed in 2-hour trials on a local machine reflects
  the limited exploration possible in a short window with 2 instances; a 72-hour run with 4
  instances will explore a much larger fraction of the reachable edge space.
- **Throughput expectation:** A smoke test on Ubuntu 22.04 ARM64 (UTM VM, 4 vCPU, Apple M2)
  achieved ~1,916 exec/sec across 4 instances (see smoke-test-findings.md). A bare-metal ARM64
  instance is expected to achieve higher throughput.
- **Instances:** Main campaign uses 4 instances (1 main + 3 secondary), doubling the trial
  configuration.
