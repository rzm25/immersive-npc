#!/usr/bin/env python3
"""Structural sanity checker for this module's SQL seeds.

The dev sandbox has no `mysql` client (workspace gotcha #11), so this is the fast
local gate for the errors that bite hardest without a database. CI still applies the
SQL to a real MySQL for the authoritative check.

Checks, per multi-row INSERT:
  1. each row's value count matches the column-list count;
  2. no row contains an unclosed string literal (an unescaped apostrophe — the fix is
     to double it: '' — workspace gotcha #6);
  3. no two value tuples are adjacent with no separating comma (`)(`) — the visible
     symptom of the "swallowed comma" trap where a row-separating comma was placed
     inside a `-- ` comment and eaten (gotcha #6).

Deliberately negative-tested by tools/check_sql_selftest.py — a linter that can't
fail is not trusted.

Usage:  python3 tools/check_sql.py sql/**/*.sql
Exit 0 = clean, 1 = problems found.
"""
import re
import sys


def strip_line_comments(text):
    """Remove `-- ...` comments that start outside a string literal. Preserves
    newlines. Doubled '' inside a string is an escaped quote, not a terminator."""
    out = []
    i, n = 0, len(text)
    in_str = False
    while i < n:
        c = text[i]
        if c == "'":
            if in_str and i + 1 < n and text[i + 1] == "'":
                out.append("''"); i += 2; continue
            in_str = not in_str
            out.append(c); i += 1; continue
        if not in_str and c == "-" and i + 1 < n and text[i + 1] == "-":
            while i < n and text[i] != "\n":
                i += 1
            continue
        out.append(c); i += 1
    return "".join(out)


def split_tuples(values_blob):
    """Walk a VALUES blob and return (list_of_tuple_bodies, missing_separator,
    unclosed_string). Handles nested parens and doubled '' escapes."""
    bodies = []
    i, n = 0, len(values_blob)
    in_str = False
    depth = 0
    body = []
    while i < n:
        c = values_blob[i]
        if in_str:
            if c == "'":
                if i + 1 < n and values_blob[i + 1] == "'":
                    body.append("''"); i += 2; continue
                in_str = False
            body.append(c); i += 1; continue
        if c == "'":
            in_str = True; body.append(c); i += 1; continue
        if c == "(":
            if depth == 0:
                body = []
            else:
                body.append(c)
            depth += 1; i += 1; continue
        if c == ")":
            depth -= 1
            if depth == 0:
                bodies.append("".join(body))
            else:
                body.append(c)
            i += 1; continue
        if depth > 0:
            body.append(c)
        i += 1
    # missing-separator: `)` followed by only whitespace then `(` (with strings masked
    # so a literal ")(" inside text can't false-positive).
    adjacency = re.search(r"\)\s*\(", strip_strings(values_blob)) is not None
    return bodies, adjacency, in_str


def strip_strings(s):
    """Replace string literal contents with X so structural regexes ignore them."""
    out = []
    i, n = 0, len(s)
    in_str = False
    while i < n:
        c = s[i]
        if c == "'":
            if in_str and i + 1 < n and s[i + 1] == "'":
                i += 2; continue
            in_str = not in_str
            out.append("'"); i += 1; continue
        out.append("X" if in_str else c)
        i += 1
    return "".join(out)


def split_top_level_commas(body):
    fields, depth, in_str, buf = [], 0, False, []
    i, n = 0, len(body)
    while i < n:
        c = body[i]
        if c == "'":
            if in_str and i + 1 < n and body[i + 1] == "'":
                buf.append("''"); i += 2; continue
            in_str = not in_str; buf.append(c); i += 1; continue
        if not in_str:
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
            elif c == "," and depth == 0:
                fields.append("".join(buf)); buf = []; i += 1; continue
        buf.append(c); i += 1
    fields.append("".join(buf))
    return fields


def check_file(path):
    problems = []
    with open(path, encoding="utf-8") as fh:
        text = strip_line_comments(fh.read())

    for stmt in text.split(";"):
        m = re.search(r"insert\s+into\s+`?(\w+)`?\s*\(([^)]*)\)\s*values\s*(.*)",
                      stmt, re.IGNORECASE | re.DOTALL)
        if not m:
            continue
        table, cols_blob, values_blob = m.group(1), m.group(2), m.group(3)
        ncols = len([c for c in cols_blob.split(",") if c.strip()])
        tuples, adjacency, unclosed_at_end = split_tuples(values_blob)
        if adjacency:
            problems.append(f"{path}: [{table}] two value tuples with no separating comma "
                            f"( )( ) — swallowed-comma trap?")
        if unclosed_at_end:
            problems.append(f"{path}: [{table}] unclosed string literal in VALUES "
                            f"(unescaped apostrophe? double it as '')")
        for body in tuples:
            nvals = len(split_top_level_commas(body))
            if nvals != ncols:
                snippet = body.strip().replace("\n", " ")[:60]
                problems.append(f"{path}: [{table}] row has {nvals} values but {ncols} "
                                f"columns: {snippet}...")
    return problems


def main(argv):
    files = argv[1:]
    if not files:
        print("usage: check_sql.py <file.sql> ...")
        return 2
    all_problems = []
    for f in files:
        all_problems += check_file(f)
    if all_problems:
        for p in all_problems:
            print("FAIL " + p)
        print(f"\n{len(all_problems)} problem(s) found")
        return 1
    print(f"OK: {len(files)} file(s) structurally clean")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
