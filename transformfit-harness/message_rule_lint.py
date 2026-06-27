#!/usr/bin/env python3
"""
message_rule_lint.py — TransformFit Harness Tier-1 message rule lint.

Checks all 8 Doctrine L1 message rules individually with per-rule failure
attribution. Fail-closed: exits 0 (GREEN) only if all 8 rules pass;
exits non-zero (RED) if any rule fails, naming WHICH rule(s) failed.

The 8 L1 message rules (TRANSFORMFIT-DOCTRINE.md L1-4..L1-11):
    1. echo user's words        — coach message includes >=1 user phrase anchor
    2. <=60 words               — word count <= 60
    3. no emoji                 — emoji count == 0
    4. no generic encouragement — banned generic phrases absent
    5. specific data only       — >=1 concrete data token (number/measurement/data keyword)
    6. honest uncertainty       — no overclaim words (guaranteed/will definitely/proven/promise/100%)
    7. weave memory             — references prior context from MEMORY block
    8. <=1 question             — question mark count <= 1

Input file format (the coach message plus context for echo/memory checks):

    USER: <the user's recent words — used for the echo check>
    MEMORY: <prior context — used for the weave-memory check>
    ---
    <the coach message body — all 8 rules apply to this>

If USER: or MEMORY: lines are absent, the corresponding rules (echo, memory)
fail (a coach message with no user context to echo / no memory to weave is
a violation).

Usage:
    python3 message_rule_lint.py <file>
    python3 message_rule_lint.py <file> --json

Exit codes:
    0 = GREEN (all 8 rules pass)
    1 = RED   (>=1 rule failed — fail-closed, per-rule attribution printed)
    2 = ERROR (could not read input file)
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from typing import List, Tuple

# ---------------------------------------------------------------------------
# Rule metadata
# ---------------------------------------------------------------------------

RULES = [
    ("R1_echo", "echo user's words (Message Rule 1, L1-4)"),
    ("R2_word_count", "<=60 words (Message Rule 2, L1-5)"),
    ("R3_no_emoji", "no emoji (Message Rule 3, L1-6)"),
    ("R4_no_generic_encouragement", "no generic encouragement (Message Rule 4, L1-7)"),
    ("R5_data_token", ">=1 specific data token (Message Rule 5, L1-8)"),
    ("R6_honest_uncertainty", "honest uncertainty / no overclaim (Message Rule 6, L1-9)"),
    ("R7_weave_memory", "weave memory (Message Rule 7, L1-10)"),
    ("R8_question_count", "<=1 question (Message Rule 8, L1-11)"),
]

# Generic encouragement phrases banned by Rule 4 (L1-7).
GENERIC_ENCOURAGEMENT = [
    "great job", "you got this", "keep it up", "you're crushing it",
    "way to go", "nice work", "awesome job", "proud of you",
    "you're doing great", "fantastic work", "good for you", "well done",
    "good job", "amazing job", "keep going", "hang in there",
]

# Overclaim words banned by Rule 6 (L1-9 honest uncertainty).
OVERCLAIM_WORDS = [
    "guaranteed", "will definitely", "definitely will", "100%",
    "promise you", "promised", "proven to work", "certain to",
    "always works", "cannot fail", "can't fail", "failsafe",
    "sure-fire", "surefire", "foolproof", "money-back guarantee",
]

# Data-token keywords for Rule 5 (L1-8). A message passes if it contains
# a number OR one of these data keywords.
DATA_KEYWORDS = [
    "readiness", "rir", "rpe", "sets", "reps", "load", "sleep",
    "soreness", "streak", "kg", "lb", "lbs", "pound", "hours",
    "hrs", "min", "minutes", "bpm", "hrv", "vo2", "calories",
    "kcal", "steps", "rest", "tempo", "warmup", "warm-up",
    "cooldown", "cool-down", "rpe ", " pr ", "1rm", "1rm",
    "volume", "intensity", "doms", "recovery",
]

# Emoji regex covering common emoji ranges (U+1F000-U+1FAFF, U+2600-U+27BF,
# U+1F1E6-U+1F1FF flags, variation selectors, dingbats).
EMOJI_RE = re.compile(
    "["
    "\U0001F1E6-\U0001F1FF"  # regional indicators (flags)
    "\U0001F300-\U0001F5FF"  # misc symbols & pictographs
    "\U0001F600-\U0001F64F"  # emoticons
    "\U0001F680-\U0001F6FF"  # transport & map
    "\U0001F700-\U0001F77F"
    "\U0001F780-\U0001F7FF"
    "\U0001F800-\U0001F8FF"
    "\U0001F900-\U0001F9FF"  # supplemental symbols
    "\U0001FA00-\U0001FA6F"
    "\U0001FA70-\U0001FAFF"
    "\U00002600-\U000026FF"  # misc symbols
    "\U00002700-\U000027BF"  # dingbats
    "\U0001F900-\U0001F9FF"
    "]+",
    re.UNICODE,
)

# Stopwords excluded from echo/memory overlap checks (too generic to count).
STOPWORDS = {
    "the", "a", "an", "and", "or", "but", "is", "are", "was", "were",
    "be", "been", "being", "to", "of", "in", "on", "at", "for", "with",
    "by", "from", "as", "it", "its", "i", "you", "your", "my", "we",
    "they", "he", "she", "this", "that", "these", "those", "so", "do",
    "does", "did", "have", "has", "had", "will", "would", "can", "could",
    "should", "may", "might", "if", "then", "than", "too", "very", "just",
    "not", "no", "yes", "me", "him", "her", "us", "them", "today", "now",
    "up", "down", "out", "about", "into", "over", "after", "before",
    "really", "feel", "feeling", "got", "get", "go", "going",
}


def _significant_words(text: str) -> set:
    """Extract significant (non-stopword) lowercase word tokens."""
    tokens = re.findall(r"[a-zA-Z][a-zA-Z'-]+", text.lower())
    return {t for t in tokens if t not in STOPWORDS and len(t) > 2}


def parse_message_file(text: str) -> Tuple[str, str, str]:
    """Parse the structured message file into (user_words, memory, coach_msg).

    Format:
        USER: <user words>
        MEMORY: <prior context>
        ---
        <coach message>

    USER: and MEMORY: lines are optional but their absence means the
    echo / memory rules will fail (no context to reference).
    """
    user_words = ""
    memory = ""
    coach_msg = text

    # Split on the first line that is exactly "---" (the separator).
    parts = text.split("\n---\n", 1)
    if len(parts) == 2:
        header, coach_msg = parts[0], parts[1]
    else:
        # No separator: treat entire content as coach message (echo/memory
        # rules will fail because there is no USER/MEMORY context).
        header = ""

    for line in header.splitlines():
        stripped = line.strip()
        if stripped.upper().startswith("USER:"):
            user_words = stripped[len("USER:"):].strip()
        elif stripped.upper().startswith("MEMORY:"):
            memory = stripped[len("MEMORY:"):].strip()

    return user_words, memory, coach_msg.strip()


# ---------------------------------------------------------------------------
# Individual rule checks — each returns (passed: bool, detail: str)
# ---------------------------------------------------------------------------

def check_echo(user_words: str, coach_msg: str) -> Tuple[bool, str]:
    """Rule 1: echo user's words — >=1 significant user word appears in message."""
    if not user_words.strip():
        return False, "no USER context provided — cannot echo user's words"
    user_tokens = _significant_words(user_words)
    if not user_tokens:
        return False, "USER context has no significant words to echo"
    coach_tokens = _significant_words(coach_msg)
    overlap = user_tokens & coach_tokens
    if not overlap:
        return False, f"message does not echo any of the user's words {sorted(user_tokens)}"
    return True, f"echoed user words: {sorted(overlap)}"


def check_word_count(coach_msg: str) -> Tuple[bool, str]:
    """Rule 2: <=60 words."""
    words = coach_msg.split()
    count = len(words)
    if count > 60:
        return False, f"message is {count} words (limit: 60)"
    return True, f"{count} words (<=60)"


def check_no_emoji(coach_msg: str) -> Tuple[bool, str]:
    """Rule 3: no emoji."""
    matches = EMOJI_RE.findall(coach_msg)
    if matches:
        return False, f"found {len(matches)} emoji: {matches}"
    return True, "no emoji"


def check_no_generic_encouragement(coach_msg: str) -> Tuple[bool, str]:
    """Rule 4: no generic encouragement phrases."""
    lower = coach_msg.lower()
    hits = [p for p in GENERIC_ENCOURAGEMENT if p in lower]
    if hits:
        return False, f"generic encouragement found: {hits}"
    return True, "no generic encouragement"


def check_data_token(coach_msg: str) -> Tuple[bool, str]:
    """Rule 5: >=1 specific data token (number or data keyword)."""
    has_number = bool(re.search(r"\d", coach_msg))
    lower = coach_msg.lower()
    keyword_hits = [k.strip() for k in DATA_KEYWORDS if k.strip() in lower]
    if has_number or keyword_hits:
        found = []
        if has_number:
            found.append("numeric data")
        if keyword_hits:
            found.append(f"keywords: {keyword_hits}")
        return True, f"specific data present ({'; '.join(found)})"
    return False, "no specific data token (no numbers and no data keywords)"


def check_honest_uncertainty(coach_msg: str) -> Tuple[bool, str]:
    """Rule 6: honest uncertainty — flag overclaim words."""
    lower = coach_msg.lower()
    hits = [w for w in OVERCLAIM_WORDS if w in lower]
    if hits:
        return False, f"overclaim language found: {hits}"
    return True, "no overclaim language"


def check_weave_memory(memory: str, coach_msg: str) -> Tuple[bool, str]:
    """Rule 7: weave memory — message references prior context from MEMORY block."""
    if not memory.strip():
        return False, "no MEMORY context provided — cannot weave memory"
    memory_tokens = _significant_words(memory)
    if not memory_tokens:
        return False, "MEMORY context has no significant words to weave"
    coach_tokens = _significant_words(coach_msg)
    overlap = memory_tokens & coach_tokens
    if not overlap:
        return False, f"message does not weave any prior memory {sorted(memory_tokens)}"
    return True, f"wove memory: {sorted(overlap)}"


def check_question_count(coach_msg: str) -> Tuple[bool, str]:
    """Rule 8: <=1 question mark."""
    count = coach_msg.count("?")
    if count > 1:
        return False, f"message has {count} question marks (limit: 1)"
    return True, f"{count} question mark(s) (<=1)"


def run(path: pathlib.Path, json_out: bool = False) -> int:
    """Run all 8 message rules on a file. Returns exit code."""
    try:
        text = path.read_text(encoding="utf-8")
    except Exception as e:
        msg = f"ERROR: could not read input file {path}: {e}"
        if json_out:
            print(json.dumps({"verdict": "ERROR", "error": str(e)}, indent=2))
        else:
            print(msg, file=sys.stderr)
        return 2

    user_words, memory, coach_msg = parse_message_file(text)

    checks = [
        ("R1_echo", check_echo(user_words, coach_msg)),
        ("R2_word_count", check_word_count(coach_msg)),
        ("R3_no_emoji", check_no_emoji(coach_msg)),
        ("R4_no_generic_encouragement", check_no_generic_encouragement(coach_msg)),
        ("R5_data_token", check_data_token(coach_msg)),
        ("R6_honest_uncertainty", check_honest_uncertainty(coach_msg)),
        ("R7_weave_memory", check_weave_memory(memory, coach_msg)),
        ("R8_question_count", check_question_count(coach_msg)),
    ]

    failures = [(rid, detail) for rid, (ok, detail) in checks if not ok]

    if json_out:
        result = {
            "verdict": "RED" if failures else "GREEN",
            "file": str(path),
            "rules": {
                rid: {"passed": ok, "detail": detail}
                for rid, (ok, detail) in checks
            },
            "failed_rules": [rid for rid, _ in failures],
        }
        print(json.dumps(result, indent=2))
    else:
        if failures:
            print(f"RED message_rule_lint: {len(failures)} rule(s) failed in {path}")
            print()
            print("Failed rules:")
            for rid, detail in failures:
                label = dict(RULES).get(rid, rid)
                print(f"  - {rid}: {label} — {detail}")
            print()
            print("All rules:")
            for rid, (ok, detail) in checks:
                label = dict(RULES).get(rid, rid)
                status = "PASS" if ok else "FAIL"
                print(f"  [{status}] {rid}: {label}")
        else:
            print(f"GREEN message_rule_lint: all 8 rules pass in {path}")

    return 1 if failures else 0


def main() -> None:
    ap = argparse.ArgumentParser(description="TransformFit 8-rule message lint (per-rule attribution, fail-closed)")
    ap.add_argument("file", type=pathlib.Path, help="message file to lint")
    ap.add_argument("--json", action="store_true", help="machine-readable JSON output")
    args = ap.parse_args()

    sys.exit(run(args.file, args.json))


if __name__ == "__main__":
    main()
