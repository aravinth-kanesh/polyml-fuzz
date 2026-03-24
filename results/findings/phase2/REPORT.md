# Campaign Report: phase2-parser-20260319-131212

Generated: Sun Mar 22 13:27:44 UTC 2026

## Campaign Parameters

| Parameter       | Value                     |
|-----------------|---------------------------|
| Phase           | 2             |
| Start date      | 'Thu Mar 19 13:12:14 UTC 2026'    |
| Elapsed time    | 72h 0m            |
| Duration target | 259200 seconds  |
| Fuzzer instances| 4|
| Seed corpus     | 838 seeds  |
| Corpus subsets  | 'stress modules datatypes'       |

## Coverage Results

| Metric                 | Value        |
|------------------------|--------------|
| Edges found (total)    | 2017 |
| Analytics samples      | 73 |
| Coverage saturation at | 2026-03-19 17:12:30 |

## Findings

| Category              | Count        |
|-----------------------|--------------|
| Unique crashes        | 3 |
| UBSan bugs            | 0   |
| ASan bugs             | 0    |
| Signal crashes        | 3  |
| Unique hangs (total)  | 110   |
| Confirmed hangs       | 0 |
| Hang-then-crash       | 0 |

## Corpus Evolution

| Metric              | Value            |
|---------------------|------------------|
| Initial seed count  | 838 |
| Evolved corpus size | 3471   |
| Total executions    | 9295140   |

## Source Coverage (LLVM)

| Metric                        | Value            |
|-------------------------------|------------------|
| Total libpolyml/ region cov.  | 28.55% |
| arm64.cpp region coverage     | 37.89% |
| Full report                   | `results/phase2-parser-20260319-131212/coverage/coverage_report.txt` |

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
./campaign/reproduce-crash.sh results/phase2-parser-20260319-131212/fuzzer01/crashes/<crash-id>
```

## File Locations

| Output                | Path                                          |
|-----------------------|-----------------------------------------------|
| AFL++ output          | `results/phase2-parser-20260319-131212/fuzzer*/`           |
| Collected crashes     | `results/phase2-parser-20260319-131212/collected-crashes/` |
| Triaged crashes       | `results/phase2-parser-20260319-131212/triaged/`           |
| Collected hangs       | `results/phase2-parser-20260319-131212/collected-hangs/`   |
| Triaged hangs         | `results/phase2-parser-20260319-131212/triaged-hangs/`     |
| Analytics CSV         | `results/phase2-parser-20260319-131212/analytics/edges_over_time.csv` |
| Saturation log        | `results/phase2-parser-20260319-131212/analytics/saturation.log` |
