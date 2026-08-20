#!/usr/bin/env python3
"""Regression tests for verifier banned-token scanner hardening.

Run: python3 scripts/test_verifier_hardening.py

Covers two hardening fixes:
  1. `strip_lean_comments` is string-literal-aware, so a banned token cannot be
     hidden from the scanner by bracketing it between `"/-"` ... `"-/"` string
     literals (Lean parses those as data and the token as live code, so the old
     stripper silently deleted the token from the scan — a false negative).
  2. `native_decide` is a banned token (non-kernel computation path).
"""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "verifier", Path(__file__).with_name("verifier.py")
)
verifier = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(verifier)


def scan(text: str) -> list[str]:
    stripped = verifier.strip_lean_comments(text)
    return [label for label, pat in verifier.BANNED_PATTERNS.items() if pat.search(stripped)]


def test_plain_banned_token_is_flagged():
    assert scan("def a := 1\n@[implemented_by foo] def b := 2\n")


def test_string_bracketed_token_is_flagged():
    # The core regression: token hidden between "/-" ... "-/" string literals.
    src = 'def s1 : String := "/-"\n@[implemented_by foo] def b := 2\ndef s2 : String := "-/"\n'
    assert scan(src), "banned token bracketed by string literals must still be caught"


def test_legit_string_with_comment_markers_is_not_flagged():
    # A legitimate string containing comment-like text is data, not a banned token,
    # and code after it must not be swallowed.
    assert scan('def s : String := "/- just data -/"\ndef g := 3\n') == []


def test_native_decide_is_flagged():
    assert "non-kernel computation" in scan("theorem t : True := by native_decide\n")


def test_real_comments_are_still_stripped():
    # sorry/axiom genuinely inside comments must not be flagged (no false positives).
    src = "def a := 1 -- sorry this is a comment\n/- axiom hidden -/\ndef b := 2\n"
    assert scan(src) == []


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
        print(f"ok  {t.__name__}")
    print(f"\n{len(tests)} passed")
