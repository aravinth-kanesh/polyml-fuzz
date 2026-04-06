# Poly/ML Compiler Fuzzing on ARM64

A coverage-guided fuzzing framework for testing the Poly/ML compiler frontend on ARM64, built as a BSc Final Year Project at King's College London.

**Motivation:** Poly/ML is a core component of the Isabelle/HOL proof assistant and forms part of its trusted computing base. This project establishes the first systematic fuzzing-based reliability baseline for Poly/ML on ARM64.

**Scope:** Lexical analysis and parsing (compiler frontend only).

**Tools:** AFL++, AddressSanitizer, UndefinedBehaviorSanitizer, LLVM source coverage.

**Report:** [aravinth-kaneshalingam-fyp-report](https://github.com/aravinth-kanesh/aravinth-kaneshalingam-fyp-report)

---

## Quick Start

```bash
# On AWS Graviton (Ubuntu 22.04 ARM64) or any ARM64 Linux machine:
git clone <repo-url> polyml-fuzz
cd polyml-fuzz

# One-command setup: installs tools, builds poly, verifies, validates seeds
./setup.sh

# Interactive wizard: configure phase, duration, instances, then launch
./fuzz.sh
```

`setup.sh` handles all dependencies and builds. `fuzz.sh` guides you through the full campaign lifecycle, including post-campaign analysis and the Phase 1 to Phase 2 corpus handoff.

---

## Repository Structure

```
polyml-fuzz/
|-- setup.sh                      # One-command setup (run this first on a fresh clone)
|-- fuzz.sh                       # Interactive wizard: configure and launch campaigns
|-- Makefile                      # Named targets: make smoke / phase1 / phase2 / report
|-- harness/
|   \-- main.c                    # Initial harness design (reference only; not used in campaigns)
|-- seeds/                        # 72 SML seed programs
|   |-- basic/                    # Core language features                (12 seeds, Phase 1)
|   |-- operators/                # Infix, precedence, fixity             (11 seeds, Phase 1)
|   |-- edge-cases/               # Lexer boundary cases, numeric literals ( 9 seeds, Phase 1)
|   |-- regression/               # Known UBSan-triggering seeds          ( 3 seeds, Phase 1)
|   |-- stress/                   # Deep nesting, long identifiers        (14 seeds, Phase 2)
|   |-- modules/                  # Structures, signatures, functors      (12 seeds, Phase 2)
|   \-- datatypes/                # ADTs, pattern matching, records       (11 seeds, Phase 2)
|-- scripts/
|   |-- ec2-setup.sh              # AWS ARM64 system dependency installer
|   |-- build-polyml.sh           # Build AFL++-instrumented Poly/ML
|   |-- build-polyml-coverage.sh  # Build LLVM coverage-instrumented Poly/ML (for analysis)
|   |-- build-harness.sh          # Build harness binary (reference only)
|   |-- coverage-report.sh        # Generate per-file LLVM source coverage report
|   |-- verify-build.sh           # Verify AFL++ instrumentation is active
|   |-- validate-seeds.sh         # Run all 72 seeds through poly
|   |-- prepare-evolved-seeds.sh  # Copy Phase 1 queue for use as Phase 2 seeds
|   |-- fetch-isabelle-seeds.sh   # Extract SML seeds from Isabelle source
|   |-- sml_mutator.py            # Grammar-aware AFL++ custom mutator
|   \-- trim-seeds.sh             # Minimise large seeds with afl-tmin
|-- campaign/
|   |-- start.sh                  # tmux launcher: opens fuzzer, monitor, and analytics panes
|   |-- launch.sh                 # Core AFL++ campaign launcher (called by start.sh)
|   |-- monitor.sh                # Live coverage/crash dashboard
|   |-- analytics.sh              # Edges/hour logging and saturation detection
|   |-- analyse.sh                # Post-campaign one-liner: crashes + triage + report + coverage
|   |-- collect-crashes.sh        # Deduplicate and minimise crashes
|   |-- triage.sh                 # Reproduce and classify crashes by fault type
|   |-- reproduce-crash.sh        # Standalone single-crash reproduction tool
|   \-- report.sh                 # Generate Markdown campaign summary
|-- results/
|   \-- early-findings/           # Bugs found before the main campaign
|-- docs/                         # Supporting documentation
\-- build/                        # Build outputs (gitignored)
```

External dependencies (cloned automatically by `./setup.sh` on Linux):
- `AFLplusplus/`: [github.com/AFLplusplus/AFLplusplus](https://github.com/AFLplusplus/AFLplusplus)
- `polyml-src/`: [github.com/polyml/polyml](https://github.com/polyml/polyml)

---

## Setup

### On AWS Graviton or any ARM64 Linux machine

```bash
git clone <repo-url> polyml-fuzz && cd polyml-fuzz
./setup.sh
```

`setup.sh` runs five steps and skips any that are already complete, so it is safe to re-run:

1. Installs system packages (clang-15, AFL++, autoconf 2.72, build tools)
2. Builds the AFL++-instrumented `poly` binary
3. Verifies AFL++ instrumentation is active in the binary
4. Validates all 72 seeds (expected: 71 pass, 1 timeout, 0 crashes)
5. Builds the LLVM coverage-instrumented `poly` binary (used by post-campaign analysis)

### On macOS (validation only)

AFL++ persistent mode does not work on macOS due to shared memory limits. You can build locally to validate seeds, but all fuzzing campaigns must run on Linux ARM64.

You will need to clone `AFLplusplus/` and `polyml-src/` manually before running `./setup.sh`.

---

## Running a Campaign

### Interactive wizard (recommended)

```bash
./fuzz.sh
```

The wizard prompts for phase, duration, and instance count, then launches the campaign inside a tmux session with three windows: the fuzzer, a live monitor, and an analytics logger. When the campaign ends, it runs post-campaign analysis automatically and offers to launch Phase 2.

### Make targets

```bash
make smoke       # 30-minute validation run (Phase 1, 1 instance)
make phase1      # Full Phase 1 campaign (3 days, 4 instances)
make phase2      # Phase 2 without evolved seeds
make phase2 EVOLVED=phase1-lexer-YYYYMMDD-HHMMSS   # Phase 2 with Phase 1 corpus
make monitor CAMPAIGN=phase1-lexer-YYYYMMDD-HHMMSS  # Live dashboard
make report CAMPAIGN=phase1-lexer-YYYYMMDD-HHMMSS   # Re-run post-campaign analysis
```

### Manual launch

```bash
./campaign/start.sh --phase 1 --duration 259200 --instances 4
```

---

## Campaign Strategy

Two sequential 3-4 day phases, each targeting a different seed subset.

### Phase 1: Lexer focus (Subset A)

Seeds: `basic/`, `operators/`, `edge-cases/`, `regression/`

These exercise the lexer: tokenisation, operators, literals, nested comments, and boundary values.

### Phase 2: Parser focus (Subset B, conditional)

Seeds: `stress/`, `modules/`, `datatypes/`

These exercise the parser with deep nesting, module hierarchies, complex types, and functor applications. Only run Phase 2 if Phase 1 was productive. Phase 2 uses a reduced timeout (5000ms), CMPLOG instrumentation on fuzzer01 and fuzzer02 to aid magic-byte solving, and the `rare` power schedule on fuzzer03 to diversify edge exploration.

When launched via `fuzz.sh`, Phase 2 is offered automatically after Phase 1 completes, with the option to seed it from Phase 1's evolved corpus. An optional `afl-cmin` minimisation step is offered before Phase 2 launches.

### Grammar-aware mutator (optional)

A custom AFL++ mutator (`scripts/sml_mutator.py`) applies structure-aware SML mutations such as pathological float literals, long identifiers, and nested expression variants. Enable with:

```bash
./campaign/launch.sh --phase 2 --grammar-mutator --duration 259200 --instances 4
```

### Saturation

Coverage saturation is declared when fewer than 10 new edges are found per hour for 3 consecutive hours. `analytics.sh` tracks this automatically and logs to `results/<campaign>/analytics/saturation.log`.

---

## Post-Campaign Analysis

When a campaign ends via `fuzz.sh` or `campaign/start.sh`, analysis runs automatically. To run it manually:

```bash
./campaign/analyse.sh <campaign-name>
```

This runs four steps in sequence:

1. Collect and deduplicate crashes (SHA-256 deduplication, then `afl-tmin` minimisation)
2. Triage each crash (reproduce, classify by fault type: UBSan / ASan / signal)
3. Generate `results/<campaign>/REPORT.md` with coverage, crash counts, and corpus stats
4. Run LLVM source coverage against the evolved corpus, writing per-file results to `results/<campaign>/coverage/`

The report includes total `libpolyml/` region coverage and `arm64.cpp` coverage if the coverage binary was built.

---

## Crash Reproduction

```bash
# Reproduce a crash from an AFL++ output directory
./campaign/reproduce-crash.sh results/<campaign>/fuzzer01/crashes/id:000001,sig:06,...

# Manual reproduction
ASAN_OPTIONS=halt_on_error=1:abort_on_error=1 \
UBSAN_OPTIONS=print_stacktrace=1 \
  poly < <crash-file>
```

---

## Findings

**ub1 (pre-campaign):** UBSan unsigned integer overflow in `libpolyml/arm64.cpp:246`, triggered by two valid SML programs (a factorial function and a simple algebraic datatype). ARM64-specific; reproducible on macOS and Linux ARM64.

```bash
poly < results/early-findings/ub1/inputs/seed_fun.sml
poly < results/early-findings/ub1/inputs/seed_datatype.sml
```

**Campaign findings:** See `results/<campaign>/REPORT.md` and `results/<campaign>/fuzzer*/crashes/` for full crash inputs, triage reports, and sanitiser logs.

---

## AFL++ Mutation Strategy

| Mutator | Effect on SML |
|---------|---------------|
| Bit/byte flip | Corrupts individual token characters |
| Arithmetic | Perturbs integer literals |
| Interesting values | Substitutes 0, MAX_INT, -1 at byte boundaries |
| Splice | Recombines two corpus entries into syntactic hybrids |
| Havoc | Stacks random mutations from the above |

An SML token dictionary (`seeds/sml.dict`) is passed via `-x` to supplement havoc with keyword and operator substitutions. The `-a text` flag biases mutations towards printable ASCII.

---

## Troubleshooting

**`afl-clang-lto not found`**
```bash
cd AFLplusplus && make distclean && make
```

**`shmget()` failures on macOS**

Run campaigns on Linux ARM64. macOS System V shared memory limits prevent AFL++ persistent mode.

**0 exec/sec**
```bash
./scripts/validate-seeds.sh   # confirm the binary and seeds work
./scripts/verify-build.sh     # confirm AFL++ instrumentation is active
```

**Coverage report shows "not generated"**
```bash
./scripts/build-polyml-coverage.sh   # or re-run ./setup.sh
```
