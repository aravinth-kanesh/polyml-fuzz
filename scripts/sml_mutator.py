#!/usr/bin/env python3
# sml_mutator.py: Structure-aware AFL++ custom mutator for Standard ML inputs
#
# Implements the AFL++ Python custom mutator interface:
#   init(seed)               -- called once at startup
#   fuzz(buf, add_buf, max_size) -- called per-mutation; returns mutated bytes
#   describe(max_len)        -- optional description of last mutation
#
# Usage (set per-fuzzer in launch.sh):
#   AFL_PYTHON_MODULE=sml_mutator AFL_CUSTOM_MUTATOR_ONLY=0 afl-fuzz ...
#   PYTHONPATH must include the directory containing this file.
#
# Strategy:
#   Rather than replacing AFL++'s byte-level mutations, this mutator supplements
#   them with structure-aware transformations that understand SML token boundaries.
#   AFL_CUSTOM_MUTATOR_ONLY=0 ensures both run in parallel.
#
#   Mutations target constructs the byte-level mutator rarely hits correctly:
#     - Pathological numeric literals (float exponents, integer edge cases)
#     - Long identifiers exceeding lexer buffer assumptions
#     - Deeply nested expressions stressing parser recursion
#     - Duplicate/swapped declarations exercising redefinition handling
#     - Unclosed or malformed comment delimiters

import random
import re

# Module-level state: tracks the last mutation applied (for describe())
_last_mutation = "none"


def init(seed):
    """Initialise random state from AFL++ seed."""
    random.seed(seed)


def describe(max_description_len):
    """Return a short description of the last mutation applied."""
    return _last_mutation[:max_description_len]


def fuzz(buf, add_buf, max_size):
    """
    Apply one structure-aware mutation to buf and return the result.
    Falls back to returning buf unchanged if anything goes wrong.
    """
    global _last_mutation
    try:
        text = buf.decode('utf-8', errors='replace')
        mutated, name = _apply_mutation(text, add_buf)
        _last_mutation = name
        result = mutated.encode('utf-8')
        return result[:max_size] if len(result) > max_size else result
    except Exception:
        _last_mutation = "fallback"
        return buf


# ---------------------------------------------------------------------------
# Mutation dispatcher
# ---------------------------------------------------------------------------

def _apply_mutation(text, add_buf):
    """Choose and apply one mutation. Returns (mutated_text, mutation_name)."""
    mutations = [
        (_mutate_float_literal,      6),   # highest weight: found real crashes
        (_mutate_integer_literal,    4),
        (_insert_pathological_float, 4),
        (_mutate_long_identifier,    3),
        (_duplicate_declaration,     3),
        (_swap_declarations,         2),
        (_insert_nested_expression,  2),
        (_corrupt_comment_delimiter, 2),
        (_splice_add_buf,            2),   # use add_buf for cross-input splicing
        (_insert_edge_string,        1),
    ]
    # Weighted random selection
    pool = [fn for fn, w in mutations for _ in range(w)]
    fn = random.choice(pool)
    return fn(text, add_buf)


# ---------------------------------------------------------------------------
# Individual mutations
# ---------------------------------------------------------------------------

# Pathological float exponents: the root cause of the crashes found in Phase 1.
# AFL++ discovered that Poly/ML's lexer does not bound-check exponent length.
_PATHOLOGICAL_FLOATS = [
    "1.0e~" + "3" * random.randint(10, 300) if random.random() > 0.5
    else "1.0e" + "3" * random.randint(10, 300)
    for _ in range(20)
] + [
    "0.5e~1000000000000000000000000000000000000",
    "3336331.5e~10333333333333333333333333333333333333333333",
    "1.0e999999999999999999999999999999999999999",
    "9.9e~999999999999999999999999",
    "1.5e~" + "9" * 200,
    "0.0e99999999999999999999999999999999999999",
]

_INTEGER_EDGE_CASES = [
    "0", "1", "~1", "2", "~2",
    "2147483647",   # Int.maxInt (32-bit)
    "~2147483648",  # Int.minInt (32-bit)
    "1073741823",
    "~1073741824",
    "4294967295",
    "9999999999999999999",
    "~9999999999999999999",
]


def _mutate_float_literal(text, _add_buf):
    """Replace an existing float literal with a pathological one."""
    # SML float pattern: digits . digits (e [~]digits)?
    pattern = r'\d+\.\d+(?:e~?\d+)?'
    matches = list(re.finditer(pattern, text))
    if not matches:
        return _insert_pathological_float(text, _add_buf)
    m = random.choice(matches)
    replacement = random.choice(_PATHOLOGICAL_FLOATS)
    return text[:m.start()] + replacement + text[m.end():], "mutate_float"


def _insert_pathological_float(text, _add_buf):
    """Insert a pathological float literal as a val binding."""
    insertion = "\nval _pf = {};\n".format(random.choice(_PATHOLOGICAL_FLOATS))
    pos = random.randint(0, max(0, len(text) - 1))
    # Insert after nearest newline to avoid breaking a token
    nl = text.rfind('\n', 0, pos)
    insert_at = nl + 1 if nl >= 0 else pos
    return text[:insert_at] + insertion + text[insert_at:], "insert_pathological_float"


def _mutate_integer_literal(text, _add_buf):
    """Replace an integer literal with an edge-case value."""
    # Match standalone integers (not part of a float)
    pattern = r'(?<!\d)~?\d+(?!\.\d)'
    matches = list(re.finditer(pattern, text))
    if not matches:
        return text, "mutate_int_noop"
    m = random.choice(matches)
    replacement = random.choice(_INTEGER_EDGE_CASES)
    return text[:m.start()] + replacement + text[m.end():], "mutate_integer"


def _mutate_long_identifier(text, _add_buf):
    """Replace a short identifier with a very long one."""
    # Simple SML identifier pattern
    pattern = r'\b([a-zA-Z][a-zA-Z0-9_\']*)\b'
    matches = [m for m in re.finditer(pattern, text)
               if m.group(1) not in _SML_KEYWORDS and len(m.group(1)) < 20]
    if not matches:
        return text, "long_id_noop"
    m = random.choice(matches)
    length = random.choice([50, 100, 200, 500, 1000])
    long_id = m.group(1) + "x" * (length - len(m.group(1)))
    return text[:m.start()] + long_id + text[m.end():], "long_identifier"


def _duplicate_declaration(text, _add_buf):
    """Duplicate a val or fun declaration."""
    pattern = r'((?:val|fun)\s+[^\n]+\n)'
    matches = list(re.finditer(pattern, text))
    if not matches:
        return text, "dup_noop"
    m = random.choice(matches)
    count = random.randint(2, 5)
    replacement = m.group(1) * count
    return text[:m.start()] + replacement + text[m.end():], "duplicate_decl"


def _swap_declarations(text, _add_buf):
    """Swap two adjacent val/fun declarations."""
    pattern = r'((?:val|fun)\s+[^\n]+\n)((?:val|fun)\s+[^\n]+\n)'
    matches = list(re.finditer(pattern, text))
    if not matches:
        return text, "swap_noop"
    m = random.choice(matches)
    swapped = m.group(2) + m.group(1)
    return text[:m.start()] + swapped + text[m.end():], "swap_decls"


def _insert_nested_expression(text, _add_buf):
    """Insert a deeply nested expression to stress parser recursion."""
    depth = random.randint(20, 100)
    # Nested let-in-end
    inner = "0"
    for i in range(depth):
        inner = "let val _n{} = {} in _n{} end".format(i, inner, i)
    insertion = "\nval _nested = {};\n".format(inner)
    nl = text.rfind('\n')
    insert_at = nl + 1 if nl >= 0 else len(text)
    return text[:insert_at] + insertion + text[insert_at:], "nested_expr"


def _corrupt_comment_delimiter(text, _add_buf):
    """Corrupt a comment delimiter to create malformed input."""
    mutations = [
        (r'\(\*', '(*(*'),    # unclosed nested open
        (r'\*\)', '*)*)')    ,  # extra close
        (r'\(\*', '(*'),       # remove close (if pair exists)
    ]
    for pattern, replacement in random.sample(mutations, len(mutations)):
        if re.search(pattern, text):
            result = re.sub(pattern, replacement, text, count=1)
            return result, "corrupt_comment"
    return text + "\n(*", "append_unclosed_comment"


def _splice_add_buf(text, add_buf):
    """Splice a fragment from add_buf into text (cross-input combination)."""
    if not add_buf:
        return text, "splice_noop"
    try:
        other = add_buf.decode('utf-8', errors='replace')
    except Exception:
        return text, "splice_decode_fail"
    # Take a random chunk from the other input
    if len(other) < 4:
        return text, "splice_too_short"
    start = random.randint(0, len(other) - 2)
    end = random.randint(start + 1, min(start + 200, len(other)))
    chunk = other[start:end]
    # Insert at a random position in text
    pos = random.randint(0, len(text))
    nl = text.rfind('\n', 0, pos)
    insert_at = nl + 1 if nl >= 0 else pos
    return text[:insert_at] + "\n" + chunk + "\n" + text[insert_at:], "splice"


def _insert_edge_string(text, _add_buf):
    """Replace or insert edge-case string literals."""
    edge_strings = [
        '""',
        '"\\n"',
        '"\\t"',
        '"\\000"',
        '"' + 'a' * 1000 + '"',
        '"' + '\\n' * 100 + '"',
    ]
    pattern = r'"[^"]*"'
    matches = list(re.finditer(pattern, text))
    if matches:
        m = random.choice(matches)
        return text[:m.start()] + random.choice(edge_strings) + text[m.end():], "edge_string"
    insertion = "\nval _s = {};\n".format(random.choice(edge_strings))
    return text + insertion, "insert_edge_string"


# ---------------------------------------------------------------------------
# SML reserved words (do not replace these as identifiers)
# ---------------------------------------------------------------------------
_SML_KEYWORDS = frozenset({
    "abstype", "and", "andalso", "as", "case", "datatype", "do", "else",
    "end", "exception", "fn", "fun", "functor", "handle", "if", "in",
    "include", "infix", "infixr", "let", "local", "nonfix", "of", "op",
    "open", "orelse", "raise", "rec", "sharing", "sig", "signature",
    "struct", "structure", "then", "type", "val", "where", "while", "with",
    "withtype", "true", "false", "nil", "ref", "it",
})
