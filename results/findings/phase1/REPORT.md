# Campaign Report: phase1-lexer-20260316-124325

Generated: Thu Mar 19 12:59:29 UTC 2026

## Campaign Parameters

| Parameter       | Value                     |
|-----------------|---------------------------|
| Phase           | 1             |
| Start date      | 'Mon Mar 16 12:43:26 UTC 2026'    |
| Elapsed time    | 72h 0m            |
| Duration target | 259200 seconds  |
| Fuzzer instances| 4|
| Seed corpus     | 35 seeds  |
| Corpus subsets  | 'basic operators edge-cases regression'       |

## Coverage Results

| Metric                 | Value        |
|------------------------|--------------|
| Edges found (total)    | 2014 |
| Analytics samples      | 73 |
| Coverage saturation at | 2026-03-16 20:43:43 |

## Findings

| Category              | Count        |
|-----------------------|--------------|
| Unique crashes        | 3 |
| UBSan bugs            | 0   |
| ASan bugs             | 0    |
| Signal crashes        | 0  |
| Unique hangs (total)  | 65   |
| Confirmed hangs       | 0 |
| Hang-then-crash       | 0 |

## Corpus Evolution

| Metric              | Value            |
|---------------------|------------------|
| Initial seed count  | 35 |
| Evolved corpus size | 2016   |
| Total executions    | 12041415   |

## Source Coverage (LLVM)

| Metric                        | Value            |
|-------------------------------|------------------|
| Total libpolyml/ region cov.  | 28.57% |
| arm64.cpp region coverage     | 39.75% |
| Full report                   | `results/phase1-lexer-20260316-124325/coverage/coverage_report.txt` |

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
./campaign/reproduce-crash.sh results/phase1-lexer-20260316-124325/fuzzer01/crashes/<crash-id>
```

## File Locations

| Output                | Path                                          |
|-----------------------|-----------------------------------------------|
| AFL++ output          | `results/phase1-lexer-20260316-124325/fuzzer*/`           |
| Collected crashes     | `results/phase1-lexer-20260316-124325/collected-crashes/` |
| Triaged crashes       | `results/phase1-lexer-20260316-124325/triaged/`           |
| Collected hangs       | `results/phase1-lexer-20260316-124325/collected-hangs/`   |
| Triaged hangs         | `results/phase1-lexer-20260316-124325/triaged-hangs/`     |
| Analytics CSV         | `results/phase1-lexer-20260316-124325/analytics/edges_over_time.csv` |
| Saturation log        | `results/phase1-lexer-20260316-124325/analytics/saturation.log` |
