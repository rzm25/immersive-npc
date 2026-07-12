#!/usr/bin/env python3
"""Negative test for tools/check_sql.py (workspace gotcha #6: a linter that can't
fail proves nothing). Feeds deliberately broken SQL and asserts each defect is
caught, plus a good sample that must pass. Exit 0 = the checker behaves correctly."""
import os
import tempfile
import check_sql

CASES = [
    # (name, sql, expect_problem)
    ("good", """INSERT INTO `t` (`a`,`b`,`c`) VALUES
        (1,2,'it''s fine'),
        (3,4,'ok');""", False),
    ("good_with_safe_comments", """INSERT INTO `t` (`a`,`b`) VALUES
        (1,'x'), -- comma BEFORE comment: safe
        (2,'y');""", False),
    ("semicolon_inside_string", """INSERT INTO `t` (`a`,`b`) VALUES
        (1,'Mind the mud; it never comes out.'),
        (2,'ok');""", False),
    ("value_count_mismatch", """INSERT INTO `t` (`a`,`b`,`c`) VALUES
        (1,2),
        (3,4,5);""", True),
    ("unbalanced_quote", """INSERT INTO `t` (`a`,`b`) VALUES
        (1,'oops don't escape');""", True),
    ("swallowed_comma_missing_separator", """INSERT INTO `t` (`a`,`b`) VALUES
        (1,'x') -- row-separating comma got eaten by this comment,
        (2,'y');""", True),
]

def run():
    failures = 0
    for name, sql, expect in CASES:
        fd, path = tempfile.mkstemp(suffix=".sql")
        with os.fdopen(fd, "w") as fh:
            fh.write(sql)
        problems = check_sql.check_file(path)
        os.unlink(path)
        got = len(problems) > 0
        status = "PASS" if got == expect else "FAIL"
        if got != expect:
            failures += 1
        print(f"  {status}: case '{name}' expected_problem={expect} got_problem={got}")
        for p in problems:
            print(f"        -> {p}")
    print(f"\nself-test: {'OK' if failures == 0 else str(failures) + ' FAILED'}")
    return 0 if failures == 0 else 1

if __name__ == "__main__":
    raise SystemExit(run())
