# Early Findings

This directory contains bugs discovered during initial testing before the main fuzzing campaign.

## ub1/ - UBSan Undefined Behaviour

**Date Found:** 2025-12-09
**Severity:** Medium (Undefined Behaviour)
**Status:** Documented, used as regression tests

### Summary
Two simple, valid SML programs trigger UBSan warnings for unsigned integer overflow in the ARM64 code generator.

### Files
- `inputs/seed_fun.sml` - Factorial function that triggers UB
- `inputs/seed_datatype.sml` - Simple datatype/eval that triggers UB
- `logs/seed_fun_asan.log` - Full sanitiser output for seed_fun
- `logs/seed_datatype_asan.log` - Full sanitiser output for seed_datatype
- `logs/exit_codes.txt` - Exit codes (134 = UBSan abort)
- `notes.txt` - Reproduction notes

### Reproduction
```bash
# Build Poly/ML with ASan+UBSan (see scripts/build-polyml.sh)
poly < results/early-findings/ub1/inputs/seed_fun.sml
poly < results/early-findings/ub1/inputs/seed_datatype.sml
```

### Bug Location
```
libpolyml/arm64.cpp:246
unsigned addition overflow
```

### Impact
These findings indicate ARM64-specific issues in the Poly/ML runtime. The bugs are triggered by valid, simple programs - not malformed input - suggesting they may affect production use.

### Regression Testing
Copies of these seeds are in `seeds/regression/` to ensure the main campaign can detect if similar bugs exist elsewhere.

---

## Adding New Findings

When crashes are discovered during the main campaign:

1. Create a new directory: `results/early-findings/crash-XXX/`
2. Include:
   - `inputs/` -- Minimised input files (`*.sml`)
   - `logs/` -- Sanitiser logs (`*_asan.log`) and exit codes
   - `notes.txt` -- Reproduction notes
3. If it's a new bug type, add to `seeds/regression/`
