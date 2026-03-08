# Poly/ML Compiler Fuzzing on ARM64

This repository contains a coverage-guided fuzzing framework for testing the Poly/ML compiler frontend on ARM64 architecture. The project evaluates the reliability of the Poly/ML lexer and parser using AFL++ with sanitiser instrumentation.

## Project Overview

**Motivation:** Poly/ML is a critical component of the Isabelle/HOL proof assistant toolchain. While the compiler frontend is implemented in memory-safe Standard ML, it indirectly exercises ARM64-specific runtime code written in C/C++. This project establishes a reliability baseline through systematic fuzzing on native ARM64 hardware.

**Scope:** Lexical analysis and parsing (compiler frontend only)

**Architecture:** Native ARM64 (AWS Graviton / Apple Silicon)

**Tools:** AFL++, AddressSanitizer, UndefinedBehaviorSanitizer

## Repository Structure

```
polyml-fuzz/
|-- harness/
|   \-- main.c                    # Initial harness design (reference only -- not used)
|-- seeds/                         # Seed corpus (69 SML programs)
|   |-- basic/                    # Core language features               (12 seeds)
|   |-- datatypes/                # Algebraic datatypes and patterns     (11 seeds)
|   |-- modules/                  # Structures, signatures, functors     (12 seeds)
|   |-- operators/                # Infix/precedence stress tests        (11 seeds)
|   |-- edge-cases/               # Lexer boundary and comment cases     ( 8 seeds)
|   |-- stress/                   # Deep nesting and complexity          (13 seeds)
|   \-- regression/               # Known UBSan-triggering seeds         ( 2 seeds)
|-- scripts/
|   |-- build-polyml.sh           # Build instrumented Poly/ML
|   |-- build-harness.sh          # Build harness (reference only -- not used in campaigns)
|   |-- verify-build.sh           # Verify instrumentation
|   |-- validate-seeds.sh         # Test all seeds parse correctly
|   |-- trim-seeds.sh             # Minimise large seeds with afl-tmin (run on AWS)
|   |-- prepare-evolved-seeds.sh  # Extract trial corpus for --use-evolved
|   \-- ec2-setup.sh              # AWS Graviton instance setup
|-- campaign/
|   |-- launch.sh                 # Start phased fuzzing campaign
|   |-- monitor.sh                # Live coverage/crash dashboard
|   |-- analytics.sh              # Edges/hour + saturation tracking
|   |-- collect-crashes.sh        # Gather and minimise crashes
|   |-- triage.sh                 # Reproduce and classify crashes
|   |-- reproduce-crash.sh        # Standalone crash reproduction
|   \-- report.sh                 # Post-campaign summary report
|-- results/
|   \-- early-findings/           # Bugs found before main campaign
|-- docs/                          # Supporting documentation
\-- build/                        # Build outputs (gitignored)
```

**External dependencies** (clone separately during setup):
- `AFLplusplus/` -- [github.com/AFLplusplus/AFLplusplus](https://github.com/AFLplusplus/AFLplusplus)
- `polyml-src/` -- [github.com/polyml/polyml](https://github.com/polyml/polyml)

## Setup on AWS Graviton

```bash
# 1. Launch ARM64 Ubuntu 22.04 instance (c7g.xlarge recommended)
# 2. SSH in and clone the repo
git clone <repo-url> polyml-fuzz
cd polyml-fuzz

# 3. Clone dependencies
git clone https://github.com/AFLplusplus/AFLplusplus
git clone https://github.com/polyml/polyml.git polyml-src

# 4. Automated EC2 setup (installs clang, build tools, system dependencies)
./scripts/ec2-setup.sh

# 5. Build instrumented Poly/ML
./scripts/build-polyml.sh

# 6. Verify everything works
./scripts/verify-build.sh

# 8. Validate seed corpus (should show 68 pass, 1 timeout, 0 crashes)
./scripts/validate-seeds.sh
```

## Campaign Strategy

The campaign is structured as two sequential 3-4 day runs, each targeting a different subset of the seed corpus. This design allows me to:

- Observe coverage saturation per subset (edges added per hour)
- Stop early if saturation occurs before the scheduled end
- Compare lexer-focused vs parser-focused coverage between phases

### Phase 1: Lexer Focus (3-4 days)

**Corpus subset A:** `basic/`, `operators/`, `edge-cases/`, `regression/` (~33 seeds)

These seeds exercise lexer tokenisation: identifiers, operators, literals, nested comments, boundary values. They are short programs with limited parse depth.

```bash
# Start Phase 1 (3 days = 259200 seconds, 4 instances for c7g.xlarge)
./campaign/launch.sh --phase 1 --duration 259200 --instances 4

# In a second terminal -- track coverage saturation hourly
./campaign/analytics.sh phase1-lexer-YYYYMMDD-HHMMSS

# Live dashboard (refresh every 30 seconds)
watch -n 30 ./campaign/monitor.sh phase1-lexer-YYYYMMDD-HHMMSS
```

### Phase 2: Parser Focus (3-4 days, conditional)

**Corpus subset B:** `stress/`, `modules/`, `datatypes/` (~36 seeds)

These seeds exercise the parser with deeply nested structures, module hierarchies, complex type expressions, and functor applications. Only run Phase 2 if Phase 1 was productive (i.e. showed non-trivial crashes or coverage).

```bash
# Start Phase 2
./campaign/launch.sh --phase 2 --duration 259200 --instances 4
```

### When to stop early

Stop a phase early if `analytics.sh` reports coverage saturation (fewer than 10 new edges per hour for 3 consecutive hours). Saturation typically occurs within 48-72 hours.

## AFL++ Mutators

AFL++ applies the following transformations to raw SML byte sequences:

| Mutator      | Description |
|--------------|-------------|
| Bit/byte flip | Flips individual bits or bytes -- corrupts token characters |
| Arithmetic   | Adds/subtracts small values -- targets integer literals |
| Interesting  | Substitutes boundary values (0, MAX_INT, -1) |
| Splice       | Recombines two corpus entries -- creates syntactically hybrid inputs |
| Havoc        | Stacks random mutations from the above set |

In addition, an SML token dictionary (`seeds/sml.dict`) is passed to AFL++ via `-x`, supplementing havoc with syntactically meaningful keyword and operator substitutions. The `-a text` flag biases mutations towards printable ASCII, reducing wasted executions on inputs that fail at tokenisation.

## Analytics: Tracking Coverage Saturation

```bash
# Run analytics in a separate terminal alongside the campaign
# Logs edges/hour to results/<campaign>/analytics/edges_over_time.csv
./campaign/analytics.sh <campaign-name>

# Default interval: 1 hour. For faster sampling during testing:
./campaign/analytics.sh <campaign-name> --interval 300   # every 5 minutes

# The CSV can be plotted to visualise saturation:
# timestamp, unix_time, edges_found, delta_edges, total_execs, execs_per_sec, unique_crashes, unique_hangs
```

Saturation is declared when fewer than 10 new edges are discovered per hour for 3 consecutive hours. The event is logged to `analytics/saturation.log`.

## Crash Reproduction (UC2)

Given a crash input from AFL++, the reproduction script reliably replays the crash and captures the full sanitiser stack trace:

```bash
# Reproduce a specific crash
./campaign/reproduce-crash.sh results/<campaign>/fuzzer01/crashes/id:000001,sig:06,...

# With a specific binary
./campaign/reproduce-crash.sh <crash-file> --poly build/polyml-instrumented/install/bin/poly

# Manual reproduction (from the report)
poly < results/<campaign>/fuzzer01/crashes/<crash-id>
```

The script outputs:
- Fault classification (ASan/UBSan/signal type)
- Full sanitiser stack trace
- Structured report saved alongside the input

## Post-Campaign Analysis

```bash
# 1. Collect and minimise all crashes
./campaign/collect-crashes.sh <campaign-name>

# 2. Classify crashes by fault type
./campaign/triage.sh <campaign-name>

# 3. Generate summary report (Markdown + plain text)
./campaign/report.sh <campaign-name>

# Review individual crash summaries
ls results/<campaign>/triaged/*.summary
```

## Pre-Campaign Findings

Bugs found during initial manual testing and infrastructure validation are documented separately in `results/early-findings/`. These are labelled as **pre-fuzzing campaign** findings and are not counted as campaign results, but are reported in the dissertation.

**ub1/** -- UBSan unsigned integer overflow in `libpolyml/arm64.cpp:246`, triggered by two valid SML programs (factorial and simple datatype). This is an ARM64-specific bug.

## Troubleshooting

**Build fails with "afl-clang-lto not found"**
```bash
# On AWS Graviton, rebuild AFL++
cd AFLplusplus && make distclean && make
```

**shmget() failures on macOS**
macOS System V shared memory limits prevent AFL++ from running in persistent mode. This is expected -- run campaigns on AWS Graviton (Linux) only.

**Fuzzers show 0 exec/sec**
Validate seeds first:
```bash
./scripts/validate-seeds.sh
```

## Project Goals

1. Build instrumented Poly/ML on ARM64 -- **COMPLETE**
2. Create reusable coverage-guided fuzzing framework -- **COMPLETE**
3. Curated seed corpus of 69 SML programs -- **COMPLETE**
4. Run Phase 1 campaign (3-4 days, Subset A) -- pending
5. Run Phase 2 campaign (3-4 days, Subset B) -- pending (conditional)
6. Analyse crashes and report findings -- pending
7. Establish reliability baseline for Poly/ML on ARM64 -- pending

## References

- [Poly/ML](https://polyml.org)
- [AFL++](https://github.com/AFLplusplus/AFLplusplus)
- [AddressSanitizer](https://clang.llvm.org/docs/AddressSanitizer.html)
- [UndefinedBehaviorSanitizer](https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html)

## Contact

Author: Aravinth Kaneshalingam
Project: BSc Final Year Project, King's College London
Supervisors: Dr. Karine Even Mendoza, Dr. Mohammad Ahmad Abdulaziz Ali Mansour

---

**Status:** Ready for AWS campaign
**Last Updated:** March 2026
