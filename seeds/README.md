# Seed Corpus

This directory contains the seed corpus used to bootstrap AFL++ fuzzing. Seeds are valid Standard ML programs organised by category.

## Current Status

**Total Seeds:** 69 [DONE] (Target: 50+ **ACHIEVED**)

### Breakdown by Category

- **basic/** (12 seeds) - Core language features, functions, arithmetic, let expressions, references, polymorphism, abstype
- **datatypes/** (11 seeds) - Lists, trees, options, ADTs, pattern matching, records, polymorphic types, mutual recursion
- **modules/** (12 seeds) - Structures, signatures, functors, opaque ascription, sharing, where type, nested modules
- **operators/** (11 seeds) - Infix operators, precedence, associativity, overloading, redefinition, composition
- **stress/** (13 seeds) - Deep nesting, long identifiers, nested comments, large expressions, pathological cases
- **edge-cases/** (8 seeds) - Ambiguous syntax, boundary values, unicode, operator edge cases, type system edges
- **regression/** (2 seeds) - Known UBSan-triggering programs from early testing

## Adding More Seeds

### Option 1: Extract from Isabelle/HOL

```bash
# Download Isabelle if not already installed
# wget https://isabelle.in.tum.de/dist/Isabelle2024_linux_arm.tar.gz
# tar xzf Isabelle2024_linux_arm.tar.gz

# Extract 30 seeds
./scripts/utils/extract-isabelle-seeds.sh \
    /path/to/Isabelle2024/src \
    seeds/modules \
    30
```

### Option 2: Extract from Poly/ML Tests

```bash
# Copy test programs from Poly/ML source
cp polyml-src/Tests/Succeed/*.ML seeds/basic/

# Validate they parse
./scripts/validate-seeds.sh
```

### Option 3: Hand-Write Stress Tests

Focus on:
- Deep recursion (100+ levels)
- Very long identifiers (1000+ chars)
- Deeply nested comments (10+ levels)
- Complex type expressions
- Large let-in blocks
- Heavily nested case expressions

See `seeds/stress/seed_deep_nesting.sml` for inspiration.

## Seed Quality Guidelines

### Good Seeds

[DONE] Parse successfully (even if they have semantic errors)
[DONE] Exercise interesting language features
[DONE] Cover different syntactic constructs
[DONE] Range from 10 lines to 500 lines
[DONE] Mix valid and edge-case programs

### Avoid

[MISS] Binary or non-text files
[MISS] Programs that immediately crash Poly/ML (save for regression/)
[MISS] Duplicate or near-duplicate programs
[MISS] Auto-generated noise without structure

## Validation

Always validate after adding seeds:

```bash
./scripts/validate-seeds.sh
```

Expected output: **68 pass, 1 timeout, 0 crashes**

Any seed that crashes poly should be moved to `regression/` and documented in `results/early-findings/`.
The single expected timeout is a known stress seed that exceeds the validation time limit.

## Dictionary File (`sml.dict`)

`seeds/sml.dict` is an AFL++ token dictionary containing SML keywords, operators,
and common idioms. It is not a seed -- AFL++ uses it during the havoc mutation stage
to substitute known SML tokens, producing mutations more likely to survive lexical
analysis. `launch.sh` picks it up automatically via `-x seeds/sml.dict`.

## Seed Corpus Strategy

The 69 seeds are split into two subsets aligned with the phased campaign strategy:

### Subset A: Phase 1 (Lexer-focused, ~33 seeds)

Categories: `basic/`, `operators/`, `edge-cases/`, `regression/`

These seeds exercise lexer tokenisation: identifiers, operators, literals, nested comments, and boundary values. Programs are short with limited parse depth, designed to stress the C++ lexer runtime.

### Subset B: Phase 2 (Parser-focused, ~36 seeds)

Categories: `stress/`, `modules/`, `datatypes/`

These seeds exercise the parser with deeply nested structures, module hierarchies, complex type expressions, and functor applications. Phase 2 is only launched if Phase 1 produces meaningful results.

Each seed is hand-crafted to:
- Cover distinct language features
- Test edge cases and boundary conditions
- Include patterns known to stress compilers (deep nesting, long identifiers, complex operators)
- Mix valid programs with syntactically tricky constructs

---

**Status:** [DONE] **COMPLETE** (69/50+ target achieved)
**Last Updated:** February 2026
