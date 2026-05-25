"""Tests that pin the Genesis-seal tamper-evidence guarantees.

These tests assert that:
  * `scripts/check-genesis-seal.py` exits non-zero on byte flips, line
    swaps, and pre-marker insertions in `data/hits.txt`.
  * The unmodified `data/hits.txt` still passes the seal check.
  * `lean_bridge._guard` refuses any rendered Lean text containing
    `axiom `, `sorry`, or `admit ` (defence-in-depth against template
    tampering), and `_genesis_integers` never lifts a non-numeric line
    like `axiom foo` into a generated lemma.
  * `kernel.probe()` aborts (RuntimeError) before any line is appended
    when the Genesis preamble of `data/hits.txt` is tampered.

Run from the repo root: `pytest tests/test_morningstar.py -q`.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
HITS = REPO_ROOT / "data" / "hits.txt"
SCRIPT = REPO_ROOT / "scripts" / "check-genesis-seal.py"
SEAL_MARKER = "--- GENESIS SEAL ---"


# ---------- helpers ----------

def _run_seal_check() -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT)],
        capture_output=True,
        text=True,
    )


@pytest.fixture
def hits_backup():
    """Back up data/hits.txt and restore it no matter what the test does.

    Tests that need to mutate the real hits.txt in-place (because the
    seal-check script and kernel.probe both read from the hard-coded
    path) request this fixture and write their tampered bytes in the
    test body. Restore is guaranteed via finally even if the test
    crashes between tampering and assertion.
    """
    original = HITS.read_bytes()
    try:
        yield original
    finally:
        HITS.write_bytes(original)


def _tamper_and_run(original: bytes, mutate) -> subprocess.CompletedProcess[str]:
    """Apply `mutate` to the file's text, run the seal check, restore.

    Restore happens before returning so callers don't have to worry
    about ordering — the file is back to pristine state on return.
    The fixture also restores as a second line of defence.
    """
    try:
        text = original.decode("utf-8")
        HITS.write_text(mutate(text), encoding="utf-8")
        return _run_seal_check()
    finally:
        HITS.write_bytes(original)


# ---------- check-genesis-seal.py: positive control ----------

def test_unmodified_hits_passes_seal():
    r = _run_seal_check()
    assert r.returncode == 0, (
        f"seal check failed on pristine hits.txt:\n"
        f"stdout={r.stdout!r}\nstderr={r.stderr!r}"
    )
    assert "Genesis seal verified" in r.stdout


# ---------- check-genesis-seal.py: tamper detection ----------

def test_flip_byte_in_line3_fails(hits_backup):
    def mutate(text: str) -> str:
        lines = text.split("\n")
        # Line 3 (1-indexed) is part of the immutable comment header.
        # Flip one letter to change exactly one byte of the preamble.
        assert lines[2].startswith("#"), "line 3 should be a comment in the preamble"
        lines[2] = lines[2].replace("a", "A", 1)
        return "\n".join(lines)

    r = _tamper_and_run(hits_backup, mutate)
    assert r.returncode != 0, "seal check must reject a one-byte flip in line 3"
    assert "Genesis seal mismatch" in (r.stderr + r.stdout)


def test_swap_genesis_lines_fails(hits_backup):
    def mutate(text: str) -> str:
        lines = text.split("\n")
        # Lines 5 and 6 (1-indexed) are the "437" and "1094" Genesis lines.
        assert lines[4] == "437" and lines[5] == "1094", (
            f"expected 437/1094 at lines 5/6, got {lines[4]!r}/{lines[5]!r}"
        )
        lines[4], lines[5] = lines[5], lines[4]
        return "\n".join(lines)

    r = _tamper_and_run(hits_backup, mutate)
    assert r.returncode != 0, "seal check must reject swapped Genesis lines"
    assert "Genesis seal mismatch" in (r.stderr + r.stdout)


def test_insert_line_before_marker_fails(hits_backup):
    def mutate(text: str) -> str:
        assert SEAL_MARKER in text
        return text.replace(SEAL_MARKER, f"INJECTED=evil\n{SEAL_MARKER}", 1)

    r = _tamper_and_run(hits_backup, mutate)
    assert r.returncode != 0, "seal check must reject a line inserted before the marker"
    assert "Genesis seal mismatch" in (r.stderr + r.stdout)


# ---------- lean_bridge guard ----------

def test_lean_bridge_guard_rejects_axiom():
    import lean_bridge
    with pytest.raises(SystemExit) as ei:
        lean_bridge._guard("theorem foo : True := trivial\naxiom bar : True\n")
    assert "axiom " in str(ei.value)


def test_lean_bridge_guard_rejects_sorry():
    import lean_bridge
    with pytest.raises(SystemExit) as ei:
        lean_bridge._guard("theorem foo : True := sorry\n")
    assert "sorry" in str(ei.value)


def test_lean_bridge_guard_rejects_admit():
    import lean_bridge
    with pytest.raises(SystemExit) as ei:
        lean_bridge._guard("theorem foo : True := by admit \n")
    assert "admit " in str(ei.value)


def test_lean_bridge_guard_allows_comment_mentioning_axiom():
    """The header literally says 'Axiom debt is []' — that must not trip the guard."""
    import lean_bridge
    # _render uses the real HEADER which contains the word "Axiom".
    rendered = lean_bridge._render([437, 1094])
    lean_bridge._guard(rendered)  # must not raise


def test_lean_bridge_skips_non_numeric_genesis_lines(tmp_path, monkeypatch):
    """Even if hits.txt is tampered to contain 'axiom foo' as a Genesis
    line, the bridge must not lift it into the generated Lean. This is
    the first line of defence; `_guard` is the second."""
    import lean_bridge
    fake = tmp_path / "hits.txt"
    fake.write_text(
        "axiom foo\n"
        "437\n"
        "1094\n"
        f"{SEAL_MARKER}\n",
        encoding="utf-8",
    )
    monkeypatch.setattr(lean_bridge, "HITS", fake)
    nums = lean_bridge._genesis_integers()
    assert nums == [437, 1094]
    rendered = lean_bridge._render(nums)
    assert "axiom foo" not in rendered
    lean_bridge._guard(rendered)  # must not raise


# ---------- kernel.probe must abort on tampered Genesis ----------

def test_probe_refuses_to_append_when_seal_fails(hits_backup):
    """kernel.probe() runs the seal check before any append. A tampered
    Genesis must raise RuntimeError *before* hits.txt grows by even one
    byte."""
    import kernel

    text = hits_backup.decode("utf-8")
    lines = text.split("\n")
    assert lines[2].startswith("#")
    lines[2] = lines[2].replace("a", "Q", 1)
    tampered = "\n".join(lines).encode("utf-8")
    HITS.write_bytes(tampered)

    size_before = HITS.stat().st_size

    with pytest.raises(RuntimeError, match="Genesis seal verification failed"):
        kernel.probe(1, 1, 0.5, 0.0)

    size_after = HITS.stat().st_size
    assert size_after == size_before, (
        "probe must not append to hits.txt when the Genesis seal fails; "
        f"size grew from {size_before} to {size_after}"
    )
