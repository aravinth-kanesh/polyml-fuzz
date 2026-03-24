# Campaign Report: phase2-parser-20260322-192228

Generated: Tue Mar 24 02:03:01 UTC 2026

## Campaign Parameters

| Parameter       | Value                     |
|-----------------|---------------------------|
| Phase           | 2             |
| Start date      | 'Sun Mar 22 19:22:28 UTC 2026'    |
| Elapsed time    | 30h 37m            |
| Duration target | 86400 seconds  |
| Fuzzer instances| 4|
| Seed corpus     | 838 seeds  |
| Corpus subsets  | 'stress modules datatypes'       |

## Coverage Results

| Metric                 | Value        |
|------------------------|--------------|
| Edges found (total)    | 2003 |
| Analytics samples      | 0 |
| Coverage saturation at | Not detected |

## Findings

| Category              | Count        |
|-----------------------|--------------|
| Unique crashes        | 2 |
| UBSan bugs            | 0   |
| ASan bugs             | 0    |
| Signal crashes        | 2  |
| Unique hangs (total)  | 24   |
| Confirmed hangs       | 0 |
| Hang-then-crash       | 0 |

## Corpus Evolution

| Metric              | Value            |
|---------------------|------------------|
| Initial seed count  | 838 |
| Evolved corpus size | 3401   |
| Total executions    | 1618639   |

## Source Coverage (LLVM)

| Metric                        | Value            |
|-------------------------------|------------------|
| Total libpolyml/ region cov.  | 28.59% |
| arm64.cpp region coverage     | 39.75% |
| Full report                   | `results/phase2-parser-20260322-192228/coverage/coverage_report.txt` |

## Fuzzer Configuration

- **Fuzzer:** AFL++ with persistent mode (`__AFL_LOOP(1000)`)
- **Mutators:** Default havoc + splice (bit/byte flips, arithmetic, splicing)
- **Instrumentation:** afl-clang-fast (LLVM edge coverage)
- **Target binary:** Poly/ML `poly` with AFL++ edge-coverage instrumentation
- **Input timeout:** 10,000 ms per test case
- **Sanitisers:** ASan + UBSan enabled at launch via `AFL_USE_ASAN=1` / `AFL_USE_UBSAN=1`

## Reproduction

To reproduce any crash:
```bash
./campaign/reproduce-crash.sh results/phase2-parser-20260322-192228/fuzzer01/crashes/<crash-id>
```

## File Locations

| Output                | Path                                          |
|-----------------------|-----------------------------------------------|
| AFL++ output          | `results/phase2-parser-20260322-192228/fuzzer*/`           |
| Collected crashes     | `results/phase2-parser-20260322-192228/collected-crashes/` |
| Triaged crashes       | `results/phase2-parser-20260322-192228/triaged/`           |
| Collected hangs       | `results/phase2-parser-20260322-192228/collected-hangs/`   |
| Triaged hangs         | `results/phase2-parser-20260322-192228/triaged-hangs/`     |
| Analytics CSV         | `results/phase2-parser-20260322-192228/analytics/edges_over_time.csv` |
| Saturation log        | `results/phase2-parser-20260322-192228/analytics/saturation.log` |
