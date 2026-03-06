# Campaign Strategy Improvements

Implemented after trial campaigns (phase1-lexer-trial-1, phase1-lexer-trial-2,
phase2-parser-trial-1) verified the full pipeline end-to-end.

## 1. SML Token Dictionary (`seeds/sml.dict`)

AFL++ default havoc mutations operate on raw bytes. Without a dictionary, mutations
on SML source produce mostly invalid tokens that the lexer rejects immediately,
limiting coverage to shallow error-handling paths. With a dictionary, AFL++
substitutes known SML tokens during the havoc stage, producing mutations more
likely to pass lexical analysis and reach the parser. This improves parser coverage
without requiring a full grammar-aware mutator.

The dictionary (`seeds/sml.dict`) contains:
- 30 SML keywords (`fun`, `val`, `datatype`, `signature`, `functor`, etc.)
- Multi-character operators (`=>`, `->`, `<=`, `>=`, `<>`, `:=`, `::`)
- Comment delimiters (`(*`, `*)`) -- important for lexer stress testing
- Common idioms (`fn x =>`, `case x of`, `datatype t =`)
- Built-in type names (`int`, `string`, `bool`, `list`, `option`)

`launch.sh` automatically passes `-x seeds/sml.dict` to every AFL++ instance if
the file exists. No additional flags are needed.

For Chapter 5: a token dictionary of SML keywords and operators was provided to
AFL++ via the `-x` flag. This supplements default byte-level mutations with
syntactically meaningful token substitutions, improving the probability that
mutations survive lexical analysis and reach the parser. No grammar-aware custom
mutator was implemented; the dictionary provides a lightweight middle ground.

## 2. Text Input Hint (`-a text`)

AFL++ is told that inputs are ASCII text via `-a text` in the fuzzer invocation.
Without this hint, AFL++ may insert null bytes and other binary sequences that
immediately cause the SML tokeniser to reject the input, wasting executions on
paths that terminate at the first character. With the hint, AFL++ biases mutations
towards printable ASCII, producing inputs that travel further into the lexer and
parser before being rejected.

This is a single flag added to the `afl-fuzz` invocation in `launch.sh` and
requires no other changes.

For Chapter 5: the `-a text` input type flag was passed to AFL++, informing it
that SML source files are ASCII text. This biases mutations towards printable
characters, reducing wasted executions on inputs that fail at tokenisation.

## 3. Power Schedule Differentiation

AFL++ supports multiple power schedules that control how much energy (mutation
budget) is assigned to each corpus entry. Running all instances with the same
schedule wastes the opportunity to explore different strategies in parallel.

The real campaigns use:
- `fuzzer01` (main): `-p explore` -- prioritises corpus entries with lower
  coverage, maximising breadth of edges found
- `fuzzer02..N` (secondaries): `-p fast` -- prioritises recently discovered
  entries, maximising throughput on promising paths

These complement each other: the main fuzzer broadens coverage while secondaries
exploit new paths quickly.

For Chapter 5: the main fuzzer instance used the `explore` power schedule to
maximise coverage breadth, while secondary instances used `fast` to maximise
throughput. This combination is recommended by the AFL++ documentation for
multi-instance campaigns.

## 4. Seed Trimming (`scripts/trim-seeds.sh`)

AFL++ mutation throughput is inversely proportional to input size. Smaller seeds
mean more mutations per second. `afl-tmin` finds the minimal input that produces
the same coverage bitmap, removing redundant content without losing coverage signal.

The largest seeds are in `seeds/stress/` (up to 3.5KB). Trimming these to their
minimal coverage-preserving form improves exec/s.

Usage (run on AWS Graviton after setup, before the real campaign):

```bash
./scripts/trim-seeds.sh --threshold 1500 --phase all
./scripts/validate-seeds.sh
```

Originals are backed up to `seeds/originals/` before trimming. Seeds that cannot
be trimmed (e.g. poly times out on them) are kept unchanged. Run on AWS rather than
Docker/macOS -- afl-tmin under ARM emulation is too slow to be practical on 20+ seeds.

For Chapter 5: seed files larger than 1,500 bytes were minimised using `afl-tmin`
prior to the real campaigns, reducing input size while preserving the AFL++ coverage
bitmap. This improves mutation throughput without sacrificing coverage signal.

## 5. Evolved Corpus Seeding (`scripts/prepare-evolved-seeds.sh`)

After a trial campaign, AFL++ has evolved the seed corpus into hundreds of inputs
that exercise code paths the original seeds do not reach directly. Starting the real
campaign from these evolved inputs means AFL++ begins from a more advanced coverage
state, rather than rediscovering the same paths from scratch.

Usage:

```bash
./scripts/prepare-evolved-seeds.sh phase1-lexer-trial-2
./campaign/launch.sh --phase 1 --duration 259200 --instances 4 --use-evolved
```

The script copies `results/<campaign>/fuzzer01/queue/` into `seeds/evolved/`,
prefixed with the campaign name to avoid collisions. `launch.sh --use-evolved` then
includes these alongside the original seeds when assembling the corpus.

Corpus sizes from trials:

| Trial campaign        | Queue size |
|-----------------------|------------|
| phase1-lexer-trial-2  | 627 inputs |
| phase2-parser-trial-1 | 523 inputs |

For Chapter 5: the real campaigns were seeded with both the original seed programs
and the evolved corpora from the trial campaigns (627 and 523 inputs respectively),
giving AFL++ a head start on coverage that would otherwise take hours to reach from
the original seeds alone.

## Summary

| Improvement              | File / Script                        | Impact | When to apply           |
|--------------------------|--------------------------------------|--------|-------------------------|
| SML token dictionary     | `seeds/sml.dict`                     | Medium | Automatic via launch.sh |
| Text input hint          | `campaign/launch.sh` (`-a text`)     | Medium | Automatic via launch.sh |
| Power schedule split     | `campaign/launch.sh` (`-p` flags)    | Low    | Automatic via launch.sh |
| Seed trimming            | `scripts/trim-seeds.sh`              | Medium | On AWS, before campaign |
| Evolved corpus seeding   | `scripts/prepare-evolved-seeds.sh`   | High   | After trial campaigns   |

The first three are automatic -- no extra steps needed when running `launch.sh`.
The last two require running the respective scripts before the real campaign starts.
