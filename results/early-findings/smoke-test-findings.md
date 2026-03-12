# Smoke Test Findings

---

## Smoke Test 1

**Date:** 09/03/2026

**Platform:** Ubuntu 22.04.5 LTS ARM64 (UTM VM on Apple M2, 4 vCPU, 8 GB RAM)

**Duration:** 30 minutes (1800 seconds)

**Instances:** 4 AFL++ fuzzer instances

**Corpus:** Subset A (35 seeds: basic/, operators/, edge-cases/, regression/)

**Purpose:** Validate that the full fuzzing pipeline operates correctly on ARM64 Linux before
committing to multi-day production campaigns. This is not a research campaign; no
fault discovery is expected or claimed from this run.

### Results Summary

| Metric | Value |
|---|---|
| Edges found (all instances) | 1,932 |
| Bitmap coverage (fuzzer01) | 11.58% |
| Exec/sec (fuzzer01) | ~632 |
| Estimated total exec/sec (4 instances) | ~1,916 |
| Unique crashes | 0 |
| Unique hangs | 1 (expected - timeout seed) |
| Corpus entries evolved | 134+ |
| AFL++ cycles completed | 8+ |
| Saturation detected | No (30 min insufficient; requires 3h <10 edges/hour) |

### Infrastructure Issues Found and Fixed

The following bugs were discovered during setup and corrected before the smoke test ran:

#### 1. autoconf version too old on Ubuntu 22.04

- **Problem:** `build-polyml.sh` calls `autoreconf`, which requires autoconf >= 2.72.
  Ubuntu 22.04 ships autoconf 2.71, causing the build to fail immediately.
- **Fix:** `scripts/ec2-setup.sh` now detects the installed autoconf version and builds
  2.72 from source if needed.

#### 2. AFL++ symbol check used regex alternation incompatible with `grep -q`

- **Problem:** `scripts/verify-build.sh` used `grep -q "__afl_area_ptr\|__sanitizer_cov"`
  with a BRE pattern containing `\|`, which is not portable. The check always failed,
  incorrectly reporting that the poly binary was not instrumented.
- **Fix:** Replaced with sequential `grep -qF` fixed-string checks. The binary is
  correctly instrumented (confirmed by `strings` showing `__afl_area_ptr`, `__afl_trace`).

#### 3. `campaign.meta` `start_date` field caused shell parse error when sourced

- **Problem:** `launch.sh` writes `start_date=Mon  9 Mar 20:05:03 UTC 2026` to
  `campaign.meta`. When `monitor.sh` sources this file, bash interprets the unquoted
  date as `start_date=Mon` followed by a command `9`, producing
  `line 4: 9: command not found`.
- **Fix:** `launch.sh` now writes `start_date='$START_DATE'` with single quotes.

### Conclusion

The ARM64 Linux pipeline is fully operational. Key validation criteria met:

- AFL++ instrumentation confirmed active in poly binary (`__afl_area_ptr` present)
- Coverage feedback working (1,932 edges found in 30 minutes)
- Exec/sec within expected range for a virtualised ARM64 environment
- Seed corpus loading and mutation operating correctly
- Analytics CSV logging functioning

---

## Smoke Test 2

**Date:** 11/03/2026

**Platform:** Ubuntu 22.04.5 LTS ARM64 (UTM VM on Apple M2, 1 vCPU, 1 GB RAM)

**Duration:** 30 minutes (1800 seconds)

**Instances:** 2 AFL++ fuzzer instances

**Corpus:** Subset A (35 seeds: basic/, operators/, edge-cases/, regression/)

**Purpose:** Validate `monitor.sh` bug fixes (colour rendering, unbound variable, stat order)
and the new tmux launcher (`campaign/start.sh`) and interactive wizard (`fuzz.sh`).

### Results Summary

| Metric | Value |
|---|---|
| Edges found (all instances) | 1,745 |
| Exec/sec (fuzzer01, peak) | ~1,016 |
| Exec/sec (fuzzer01, end) | ~157 |
| Unique crashes | 0 |
| Unique hangs | 5 |
| Saturation detected | No (30 min insufficient) |

### Hangs Analysis

All 5 hangs are infinite recursion patterns — mutations of `seed_fun.sml` (factorial function)
where AFL++ removed the base case or substituted an unbounded argument (e.g. `fact (n - 5)`
with no termination condition). On macOS these hit the shared memory limit and produce
`sig:09` (SIGKILL); on Linux they hit the 10,000 ms per-test-case timeout correctly and
are recorded as hangs. These are expected fuzzer-generated inputs exercising the timeout
path and are not indicative of Poly/ML bugs.

### Exec/sec Drop

Exec/sec fell from ~1,016 at the start of the run to ~157 by the end. This is attributable
to memory pressure: the UTM VM was configured with only 1 GB RAM, and as the evolved corpus
grew to hundreds of entries, the fork-server's memory footprint exceeded available RAM,
causing heavy swapping. This is a VM configuration constraint only. The production ARM64
instance (4 OCPUs, 24 GB RAM) will not be subject to this.

### Infrastructure Issues Found and Fixed

#### 1. `monitor.sh` ANSI escape codes rendered as raw text

- **Problem:** `watch -n 30` was used without `-c`; colour codes were printed literally.
- **Fix:** Changed to `watch -c -n 30` in `campaign/monitor.sh` and `Makefile`.

#### 2. `monitor.sh` unbound variable `RUNNING_FUZZERS`

- **Problem:** `pgrep | wc -l | tr -d ' '` left an embedded newline, causing
  `[[ : 0\n0: syntax error` in arithmetic context.
- **Fix:** Replaced with `pgrep -c` which outputs a plain integer count.

#### 3. `monitor.sh` `stat` order: Linux vs macOS

- **Problem:** `stat -f %m` (macOS syntax) was called first; on Linux it outputs
  `File: <name>` to stdout before failing, capturing that string into `LAST_UPDATE`.
- **Fix:** Linux `stat -c %Y` is tried first; macOS `stat -f %m` is the fallback.

#### 4. `campaign.meta` `corpus_dirs` field word-split on source

- **Problem:** `corpus_dirs=basic operators edge-cases regression` (unquoted) caused
  bash to execute `operators` as a command when `monitor.sh` sourced the file.
- **Fix:** `launch.sh` now writes `corpus_dirs='${CORPUS_DIRS[*]}'` with single quotes.

### Conclusion

Pipeline confirmed working on ARM64 Linux with the new `start.sh` tmux launcher and
`fuzz.sh` interactive wizard. Monitor bugs resolved. The exec/sec drop is a VM RAM
constraint, not a framework issue.

---

## Smoke Test 3 - EC2 Phase 1 (Planned)

**Platform:** AWS EC2 ARM64 (Ubuntu 22.04) or Oracle Cloud Ampere A1

**Purpose:** Validate `ec2-setup.sh` end-to-end on a bare-metal ARM64 Linux instance,
confirm exec/sec >1,000 without memory pressure, and verify `start.sh`/`fuzz.sh`/`Makefile`
workflow on a remote instance before committing to a 3-4 day Phase 1 campaign.

**Expected criteria to pass:**
- `verify-build.sh` reports poly binary instrumented
- `exec/sec > 1,000` sustained
- `edges found > 500` after 30 minutes
- No unexpected sig:09 crashes (would indicate Linux config issue)
- `analytics.sh` saturation CSV logs without error

*Results to be filled in after run.*

---

## Smoke Test 4 - EC2 Phase 2 with Evolved Corpus (Planned)

**Platform:** AWS EC2 ARM64 (Ubuntu 22.04) or Oracle Cloud Ampere A1

**Purpose:** Validate the Phase 1 -> Phase 2 handoff: confirm that the evolved corpus from
Smoke Test 3 is correctly passed to Phase 2 via `--evolved`, and that Phase 2 seeds
(Subset B: stress/, modules/, datatypes/) load and mutate correctly.

**Expected criteria to pass:**
- Phase 2 campaign starts with evolved corpus entries visible in `queue/`
- `edges found` after 30 minutes comparable to Smoke Test 3 (seeds cover different paths)
- No regression in exec/sec vs Smoke Test 3

*Results to be filled in after run.*
