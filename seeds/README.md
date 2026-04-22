# Seed Corpus

This directory contains the seed corpus used to bootstrap AFL++ fuzzing. Seeds are valid Standard ML programs organised by category.

## Summary

**Total Seeds:** 72

### Breakdown by Category

- **basic/** (12 seeds) - Core language features, functions, arithmetic, let expressions, references, polymorphism, abstype
- **datatypes/** (11 seeds) - Lists, trees, options, ADTs, pattern matching, records, polymorphic types, mutual recursion
- **modules/** (12 seeds) - Structures, signatures, functors, opaque ascription, sharing, where type, nested modules
- **operators/** (11 seeds) - Infix operators, precedence, associativity, overloading, redefinition, composition
- **stress/** (14 seeds) - Deep nesting, long identifiers, nested comments, large expressions, deep function application chains
- **edge-cases/** (9 seeds) - Ambiguous syntax, boundary values, unicode, operator edge cases, numeric literal formats (word/hex/real)
- **regression/** (3 seeds) - Known UBSan-triggering programs and parser error-recovery paths

## Validation

```bash
./scripts/validate-seeds.sh
```

Expected output: **71 pass, 1 timeout, 0 crashes**

The single expected timeout is a known stress seed that exceeds the validation time limit. Any seed that crashes poly should be moved to `regression/` and documented in `results/early-findings/`.

## Dictionary File (`sml.dict`)

`seeds/sml.dict` is an AFL++ token dictionary containing SML keywords, operators,
and common idioms. It is not a seed -- AFL++ uses it during the havoc mutation stage
to substitute known SML tokens, producing mutations more likely to survive lexical
analysis. `launch.sh` picks it up automatically via `-x seeds/sml.dict`.

## Seed Corpus Strategy

The 72 seeds are split into two subsets aligned with the phased campaign strategy:

### Subset A: Phase 1 (Lexer-focused, 35 seeds)

Categories: `basic/`, `operators/`, `edge-cases/`, `regression/`

These seeds exercise lexer tokenisation: identifiers, operators, literals, nested comments, and boundary values. Programs are short with limited parse depth, designed to stress the C++ lexer runtime.

### Subset B: Phase 2 (Parser-focused, 37 seeds)

Categories: `stress/`, `modules/`, `datatypes/`

These seeds exercise the parser with deeply nested structures, module hierarchies, complex type expressions, and functor applications.

Each seed is hand-crafted to:
- Cover distinct language features
- Test edge cases and boundary conditions
- Include patterns known to stress compilers (deep nesting, long identifiers, complex operators)
- Mix valid programs with syntactically tricky constructs
