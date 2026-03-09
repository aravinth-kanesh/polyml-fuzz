# Smoke Test Findings

**Date:** 09/03/2026

**Platform:** Ubuntu 22.04.5 LTS ARM64 (UTM VM on Apple M2, 4 vCPU, 8 GB RAM)

**Duration:** 30 minutes (1800 seconds)

**Instances:** 4 AFL++ fuzzer instances

**Corpus:** Subset A (35 seeds: basic/, operators/, edge-cases/, regression/)

---

## Purpose

Validate that the full fuzzing pipeline operates correctly on ARM64 Linux before
committing to multi-day production campaigns. This is not a research campaign; no
fault discovery is expected or claimed from this run.

---

## Results Summary

| Metric | Value |
|---|---|
| Edges found (all instances) | 1,932 |
| Bitmap coverage (fuzzer01) | 11.58% |
| Exec/sec (fuzzer01) | ~632 |
| Estimated total exec/sec (4 instances) | ~1,916 |
| Unique crashes | 0 |
| Unique hangs | 1 (expected -- timeout seed) |
| Corpus entries evolved | 134+ |
| AFL++ cycles completed | 8+ |
| Saturation detected | No (30 min insufficient; requires 3h <10 edges/hour) |

---

## Infrastructure Issues Found and Fixed

The following bugs were discovered during setup and corrected before the smoke test ran:

### 1. autoconf version too old on Ubuntu 22.04

- **Problem:** `build-polyml.sh` calls `autoreconf`, which requires autoconf >= 2.72.
  Ubuntu 22.04 ships autoconf 2.71, causing the build to fail immediately.
- **Fix:** `scripts/ec2-setup.sh` now detects the installed autoconf version and builds
  2.72 from source if needed.

### 2. AFL++ symbol check used regex alternation incompatible with `grep -q`

- **Problem:** `scripts/verify-build.sh` used `grep -q "__afl_area_ptr\|__sanitizer_cov"`
  with a BRE pattern containing `\|`, which is not portable. The check always failed,
  incorrectly reporting that the poly binary was not instrumented.
- **Fix:** Replaced with sequential `grep -qF` fixed-string checks. The binary is
  correctly instrumented (confirmed by `strings` showing `__afl_area_ptr`, `__afl_trace`).

### 3. `campaign.meta` `start_date` field caused shell parse error when sourced

- **Problem:** `launch.sh` writes `start_date=Mon  9 Mar 20:05:03 UTC 2026` to
  `campaign.meta`. When `monitor.sh` sources this file, bash interprets the unquoted
  date as `start_date=Mon` followed by a command `9`, producing
  `line 4: 9: command not found`.
- **Fix:** `launch.sh` now writes `start_date='$START_DATE'` with single quotes.

---

## Conclusion

The ARM64 Linux pipeline is fully operational. Key validation criteria met:

- AFL++ instrumentation confirmed active in poly binary (`__afl_area_ptr` present)
- Coverage feedback working (1,229 edges found in 30 minutes)
- Exec/sec within expected range for a virtualised ARM64 environment
- Seed corpus loading and mutation operating correctly
- Analytics CSV logging functioning

The framework is ready for production 3-4 day campaigns on a persistent ARM64 instance.
