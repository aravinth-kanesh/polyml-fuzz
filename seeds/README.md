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

Expected output:
- Most seeds should pass or have parse errors (OK)
- Timeouts are concerning (indicates hang)
- Crashes should be rare (unless in regression/)

## Seed Corpus Strategy

The 69 seeds are strategically designed to maximise bug discovery:

1. **Core Features** (12 basic seeds) - Exercise fundamental language constructs
2. **Type System** (11 datatype + 12 module seeds) - Test complex type checking and module system
3. **Parser Stress** (11 operator + 13 stress + 8 edge-case seeds) - Pathological inputs designed to find parser bugs
4. **Known Issues** (2 regression seeds) - Programs that previously triggered sanitiser warnings

Each seed is hand-crafted to:
- Cover distinct language features
- Test edge cases and boundary conditions
- Include patterns known to stress compilers (deep nesting, long identifiers, complex operators)
- Mix valid programs with syntactically tricky constructs

---

**Status:** [DONE] **COMPLETE** (69/50+ target achieved)
**Last Updated:** January 2026
