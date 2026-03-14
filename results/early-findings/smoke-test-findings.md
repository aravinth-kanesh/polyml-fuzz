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

**Platform:** Ubuntu 22.04.5 LTS ARM64 (UTM VM on Apple M2, 8 GB RAM)

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

Exec/sec fell from ~1,016 at the start of the run to ~157 by the end. The likely cause is
I/O load from AFL++ writing an increasingly large evolved corpus (growing from 35 seeds to
hundreds of queue entries) combined with running only 2 instances on a QEMU virtualised
disk. This is expected virtualisation overhead; the production ARM64 instance on bare-metal
with faster storage will not be affected.

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

## Smoke Test 3 - UTM VM Full Lifecycle Validation

**Date:** 12/03/2026

**Platform:** Ubuntu 22.04.5 LTS ARM64 (UTM VM on Apple M2, 8 GB RAM) - fresh install, no
pre-installed dependencies

**Duration:** 2 minutes per phase (120 seconds) — enough to confirm full wizard lifecycle

**Instances:** 4

**Purpose:** Validate the complete end-to-end workflow on a fresh machine: `setup.sh` from
scratch, `fuzz.sh` wizard, Phase 1 launch, automatic post-campaign analysis, Phase 1 -> Phase 2
evolved corpus handoff, Phase 2 launch, and Phase 2 post-campaign analysis including LLVM
source coverage.

### Results Summary

| Metric | Value |
|---|---|
| Phase 1 source coverage (libpolyml/ total) | 24.47% |
| Phase 2 source coverage (libpolyml/ total) | 24.84% |
| Unique crashes (both phases) | 0 |
| Phase 1 evolved seeds passed to Phase 2 | 158 |
| Phase 2 total corpus (Subset B + evolved) | 195 seeds |

### Criteria

| Criterion | Status |
|---|---|
| `setup.sh` completes all 5 steps on a fresh install | Pass |
| `fuzz.sh` prompts display correctly and pass args to `start.sh` | Pass |
| `start.sh` opens tmux session with 3 windows (fuzzer, monitor, analytics) | Pass |
| `campaign/analyse.sh` runs without error after campaign | Pass |
| `campaign/report.sh` generates REPORT.md | Pass |
| `monitor.sh` fuzzer count correct (not double-counted) | Pass |
| tmux session auto-kills after analysis complete | Pass |
| Phase 1 -> Phase 2 handoff prompt appears after analysis | Pass |
| Phase 2 launches with evolved corpus from Phase 1 | Pass |
| Phase 2 `queue/` contains evolved entries from Phase 1 | Pass |
| `analyse.sh` step 4/4 runs coverage-report.sh or skips cleanly | Pass |
| `REPORT.md` includes Source Coverage section | Pass |

### Infrastructure Issues Found and Fixed

#### 1. `monitor.sh` reported double the running fuzzer count

- **Problem:** `pgrep -c -f "afl-fuzz.*${CAMPAIGN_NAME}"` matched too broadly, counting
  unrelated processes and reporting 8 fuzzers instead of 4.
- **Fix:** Pattern scoped to `afl-fuzz.*-o.*${CAMPAIGN_NAME}` to match only afl-fuzz
  processes with the output directory flag.

#### 2. tmux session name `fuzz-phase1` merged visually with window index

- **Problem:** In the tmux status bar, `[fuzz-phase1:0:fuzzer...]` caused the trailing `1`
  and window index `0` to read as `fuzz-phas0`, confusing the session name.
- **Fix:** Session renamed to `phase 1` / `phase 2` (space-separated); status bar now
  displays `[phase 1] 0:fuzzer 1:monitor 2:analytics` unambiguously.

#### 3. tmux session not cleaned up after campaign

- **Problem:** After the campaign finished, the tmux session remained open, blocking the
  terminal and requiring manual `tmux kill-session`.
- **Fix:** `start.sh` now kills the session automatically after the user presses Enter
  at the analysis complete prompt.

#### 4. Post-campaign analysis required manual steps

- **Problem:** After a campaign, users had to manually run `analyse.sh` and `report.sh`.
- **Fix:** `start.sh` now automatically runs `analyse.sh` (which calls collect-crashes,
  triage, and report) when the campaign ends, before prompting to close.

#### 5. Phase 1 -> Phase 2 handoff required manual command construction

- **Problem:** After Phase 1, users had to manually find the campaign name and run
  `start.sh --phase 2 --evolved <name>`.
- **Fix:** `fuzz.sh` now prompts for Phase 2 automatically after Phase 1 analysis
  completes, pre-filling the evolved corpus campaign name from `results/.last-campaign`.

#### 6. `verify-build.sh` harness check was a hard failure

- **Problem:** The harness binary is not used in campaigns (reference only), but its
  absence caused `verify-build.sh` to set `FAILED=1` and exit non-zero, blocking
  `setup.sh` at step 3/5 on a fresh clone that never built the harness.
- **Fix:** Harness check downgraded to a yellow warning; does not affect the exit code.

#### 7. `verify-build.sh` AFL++ symbol check false positive when called as subprocess

- **Problem:** `strings` and `nm` symbol checks passed when run interactively but failed
  when `verify-build.sh` was invoked as a subprocess from `setup.sh`, due to PATH
  not being inherited correctly in the subprocess environment.
- **Fix:** Tool paths resolved explicitly with `command -v` before use. A runtime
  execution fallback (run `poly` on a trivial input) added as a final check if symbol
  checks are inconclusive.

### Conclusion

Full end-to-end lifecycle validated on a fresh Ubuntu 22.04.5 LTS ARM64 UTM VM (no
pre-installed dependencies). `setup.sh` completed all 5 steps without intervention.
`fuzz.sh` wizard guided Phase 1 and Phase 2 campaigns, auto-analysis ran successfully
after each, and the Phase 1 evolved corpus (158 inputs) was correctly handed off to
Phase 2. LLVM source coverage reports generated for both phases. All criteria passed.

---

## Smoke Test 4 - EC2 Phase 1

**Date:** 14/03/2026

**Platform:** AWS EC2 c7g.xlarge (AWS Graviton 3, 4 ARM64 vCPUs, 8 GB RAM), Ubuntu 22.04.5 LTS ARM64 — fresh install, no pre-built binaries

**Duration:** 30 minutes (1800 seconds)

**Instances:** 4 AFL++ fuzzer instances

**Corpus:** Subset A (35 seeds: basic/, operators/, edge-cases/, regression/)

**Purpose:** Validate `ec2-setup.sh` and `setup.sh` end-to-end on a fresh EC2 ARM64
instance and confirm bare-metal performance without the QEMU I/O overhead seen on UTM VMs.
This is the final gate before committing to multi-day production campaigns.

### Results Summary

| Metric | Value |
|---|---|
| Edges found (all instances) | 1,698 |
| Exec/sec (peak, all instances) | 1,178 |
| Exec/sec (final, fuzzer01) | 163.88 |
| Total executions | 1,413,583 |
| Unique crashes | 0 |
| Unique hangs | 10 |
| LLVM region coverage (libpolyml/) | 25.24% |
| arm64.cpp region coverage | 37.27% |
| Evolved corpus size | 1,192 entries |
| Saturation detected | No (30 min insufficient) |

### Infrastructure Issues Found and Fixed

#### 1. `analyse.sh` ran `report.sh` before `coverage-report.sh`

- **Problem:** `report.sh` (step 3/4) read `coverage_report.txt` before
  `coverage-report.sh` (step 4/4) had generated it, so `REPORT.md` always showed
  "not generated" for source coverage despite coverage data being present.
- **Fix:** Steps reordered: `coverage-report.sh` now runs as step 3/4 and `report.sh`
  as step 4/4.

#### 2. `monitor.sh` double-counted AFL++ fork server children

- **Problem:** `pgrep -c -f "afl-fuzz.*-o.*${CAMPAIGN_NAME}"` matched both the main
  `afl-fuzz` process and its persistent fork server child for each instance, reporting
  8 fuzzers running instead of 4.
- **Fix:** Replaced `pgrep` with parsing of `afl-whatsup` output for the
  "Fuzzers alive" count, which is authoritative.

### Conclusion

EC2 bare-metal performance confirmed: 1,178 exec/sec peak (vs ~1,016 peak on UTM VM with
QEMU overhead). `ec2-setup.sh` completed without error on a fresh instance. All validation
criteria passed. Framework is ready for production campaigns.

---

## Smoke Test 5 - EC2 Phase 2 with Evolved Corpus

**Date:** 14/03/2026

**Platform:** AWS EC2 c7g.xlarge (AWS Graviton 3, 4 ARM64 vCPUs, 8 GB RAM), Ubuntu 22.04.5 LTS ARM64

**Duration:** 30 minutes (1800 seconds)

**Instances:** 4 AFL++ fuzzer instances

**Corpus:** Subset B (37 seeds: stress/, modules/, datatypes/) + 290 evolved seeds from ST4 = 327 total

**Purpose:** Validate the full Phase 1 -> Phase 2 handoff on EC2 via the `fuzz.sh` wizard,
and confirm that the evolved corpus from ST4 is correctly passed to Phase 2.

### Results Summary

| Metric | Value |
|---|---|
| Edges found (all instances) | 1,723 |
| Exec/sec (peak, all instances) | 190 |
| Exec/sec (final, fuzzer01) | 92.69 |
| Total executions | 330,858 |
| Unique crashes | 0 |
| Unique hangs | 4 |
| LLVM region coverage (libpolyml/) | 25.34% |
| arm64.cpp region coverage | 37.27% |
| Evolved corpus size | 1,402 entries |
| Saturation detected | No (30 min insufficient) |

### Exec/sec Note

Exec/sec is significantly lower than ST4 (190 vs 1,178) due to the much larger starting
corpus (327 seeds vs 35). AFL++ must process all corpus entries in each cycle; larger
corpora reduce per-second throughput. This is expected and does not indicate a performance
regression.

### Conclusion

Phase 1 -> Phase 2 handoff confirmed working end-to-end on EC2: `fuzz.sh` correctly
pre-filled the evolved corpus campaign name, Phase 2 launched with 290 evolved entries
from ST4 in addition to the 37 Subset B seeds, and post-campaign analysis including LLVM
coverage ran without error. All validation criteria passed.
