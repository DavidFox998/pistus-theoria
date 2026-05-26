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

import os
import subprocess
import sys
import threading
import time
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
HITS = REPO_ROOT / "data" / "hits.txt"
SCRIPT = REPO_ROOT / "scripts" / "check-genesis-seal.py"
INTEGRITY_SCRIPT = REPO_ROOT / "scripts" / "check-ledger-integrity.py"
CHECKPOINT = REPO_ROOT / "data" / "hits.txt.checkpoint"
SEAL_MARKER = "--- GENESIS SEAL ---"


@pytest.fixture
def fresh_checkpoint():
    """Refresh data/hits.txt.checkpoint to match the *current* live
    hits.txt at test entry; restore the prior checkpoint at teardown.

    Why: the `kernel-numerics` validation step runs `kernel.probe()`
    in a separate pytest process. `tests/test_kernel.py` monkeypatches
    `kernel.HITS` to a throwaway file but does NOT monkeypatch
    `kernel.CHECKPOINT`, so every probe in that suite overwrites the
    real `data/hits.txt.checkpoint` with `(size_of_fake, sha_of_fake)`.
    By the time the `morningstar-tamper` step runs, the checkpoint
    on disk no longer matches the (untouched) real hits.txt. Without
    this refresh, the at-rest integrity tests below would fail with
    a spurious "rewritten in place" error that is entirely a
    cross-suite artefact, not a real tamper.

    The broader cross-suite snapshot fix is tracked separately as
    follow-up #58 ("Reset the ledger to its committed snapshot after
    every test run"). This per-test refresh is the minimal change
    needed to keep task #53's integrity tests deterministic under
    the existing validation harness.
    """
    import hashlib as _hashlib
    original_cp = CHECKPOINT.read_bytes() if CHECKPOINT.exists() else None
    data = HITS.read_bytes()
    CHECKPOINT.write_text(
        f"{len(data)} {_hashlib.sha256(data).hexdigest()}\n",
        encoding="utf-8",
    )
    try:
        yield
    finally:
        if original_cp is not None:
            CHECKPOINT.write_bytes(original_cp)
        else:
            CHECKPOINT.unlink(missing_ok=True)


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

    Task #59: the entire snapshot → (test body mutate) → restore
    window is wrapped in `kernel.hits_exclusive_lock()`, the same
    sidecar flock that `kernel._append_line` takes. This serialises
    the fixture against any concurrently-running probe workflow
    (`zeta-burst-101-10000` / `zeta-sieve-14159-100000`) so that a
    sibling append cannot land between snapshot and restore and get
    silently overwritten. Without this lock the tamper fixture was
    documented in `replit.md` as "bypasses _append_line and can
    clobber concurrent writes"; with it, the lock is now the shared
    contract.
    """
    import kernel
    with kernel.hits_exclusive_lock():
        original = HITS.read_bytes()
        try:
            yield original
        finally:
            HITS.write_bytes(original)


def _atomic_write_bytes(path: Path, data: bytes) -> None:
    """Replace `path`'s contents atomically via a sibling tempfile + os.replace.

    `Path.write_text` / `Path.write_bytes` open in 'w'/'wb' mode, which
    truncates the file to zero bytes BEFORE the new content is written.
    Any concurrent reader (e.g. the live `zeta-burst` workflow calling
    `kernel._verify_seal`) that opens the file inside that window sees
    an empty file with no Genesis-seal marker — see
    `docs/CHANGELOG.md` task #52. `os.replace` is POSIX-atomic on the
    same filesystem, so concurrent readers see either the old bytes
    or the new bytes, never a torn intermediate state.
    """
    tmp = path.with_name(path.name + ".tamper.tmp")
    tmp.write_bytes(data)
    os.replace(tmp, path)


def _tamper_and_run(original: bytes, mutate) -> subprocess.CompletedProcess[str]:
    """Apply `mutate` to the file's text, run the seal check, restore.

    Restore happens before returning so callers don't have to worry
    about ordering — the file is back to pristine state on return.
    The fixture also restores as a second line of defence.
    """
    try:
        text = original.decode("utf-8")
        _atomic_write_bytes(HITS, mutate(text).encode("utf-8"))
        return _run_seal_check()
    finally:
        _atomic_write_bytes(HITS, original)


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


# ---------- regression: concurrent tamper must not break a live probe loop ----------


def test_verify_seal_survives_concurrent_atomic_rewriter(hits_backup):
    """Task #52 regression: while the morningstar-tamper test fixture is
    rewriting `data/hits.txt` in a loop, a concurrent `kernel._verify_seal`
    call (the inner loop of `zeta_burst`) must NOT raise.

    Before the fix:
      - the fixture used `Path.write_text`, which truncates the file
        before writing — readers saw an empty file with no Genesis
        marker, so `_verify_seal` raised
        `'--- GENESIS SEAL ---' is not in list`.
      - any kernel.probe / zeta_burst running alongside
        morningstar-tamper failed immediately, even though the on-disk
        seal was intact.

    After the fix:
      - the fixture writes via `_atomic_write_bytes` (sibling tempfile
        + os.replace), so readers see either the old or the new bytes.
      - `_verify_seal` also retries a few times to absorb any other
        transient mid-write reader (defence in depth).
    """
    import kernel

    original = hits_backup
    # Mutation preserves the marker — the seal still verifies on the
    # tampered bytes' content for the *file existence* test; what we
    # care about is that the kernel never sees a truncated read.
    tampered = original  # identity mutation is enough: this isolates
    # the race itself (atomic vs truncate-then-write) from any
    # hash-mismatch noise.

    stop = threading.Event()
    errors: list[BaseException] = []

    def rewriter() -> None:
        try:
            while not stop.is_set():
                _atomic_write_bytes(HITS, tampered)
                _atomic_write_bytes(HITS, original)
        except BaseException as e:  # noqa: BLE001
            errors.append(e)

    t = threading.Thread(target=rewriter, daemon=True)
    t.start()
    try:
        deadline = time.monotonic() + 1.0
        iterations = 0
        while time.monotonic() < deadline:
            kernel._verify_seal()
            iterations += 1
        assert iterations > 50, (
            f"sanity: expected many _verify_seal cycles in 1s, got {iterations}"
        )
    finally:
        stop.set()
        t.join(timeout=2.0)
    assert not errors, f"rewriter thread crashed: {errors}"


# ---------- regression: snapshot/restore must not lose concurrent appends ----------


def test_snapshot_restore_does_not_lose_concurrent_appends(fresh_checkpoint):
    """Task #59: a `morningstar-tamper`-style snapshot → mutate →
    restore cycle on `data/hits.txt` must not silently drop lines
    appended by a sibling probe workflow during the mutate window.

    Pre-task-#59 hole: `_append_line` took an `fcntl.flock` on its
    own append handle (task #54), but the tamper fixture bypassed
    `_append_line` entirely and used a plain `read_bytes` +
    `write_bytes` snapshot/restore with no lock at all. A sibling
    appender could land a line between snapshot and restore, and
    the restore would clobber it — `replit.md` called this out as
    a known gotcha.

    Post-task-#59 contract: both parties acquire the shared sidecar
    `kernel.hits_exclusive_lock()` (sidecar because tamper helpers
    may `os.replace` the ledger; a flock on HITS itself would be
    orphaned by the inode swap). This test exercises the contract
    end-to-end: a background thread hammers `_append_line` while
    the main thread runs the snapshot → atomic-replace mutate →
    restore cycle. After everything settles, every appended line
    must be present in the final `hits.txt`.

    Without the fix the appender would (a) deadlock on a stale flock
    or (b) succeed during the mutate window and have its line wiped
    by restore. With the fix it queues on the sidecar lock and all
    lines survive.
    """
    import kernel

    # Don't use `hits_backup` — it would also acquire the sidecar
    # lock and we'd never release it for the background appender to
    # make progress between main-thread tamper cycles. Do our own
    # snapshot + finally restore so the live ledger comes back intact
    # (along with any appender lines we deliberately wrote, which we
    # strip at the end so we don't pollute hits.txt across runs).
    original_bytes = HITS.read_bytes()
    original_cp = CHECKPOINT.read_bytes()

    marker_tag = f"TASK59_REGRESSION_PROBE_{os.getpid()}"
    appender_count = 30
    appended: list[str] = []
    appender_errors: list[BaseException] = []
    stop = threading.Event()
    started = threading.Event()

    def appender() -> None:
        try:
            started.set()
            for i in range(appender_count):
                if stop.is_set():
                    break
                line = f"{marker_tag}_{i:04d}"
                kernel._append_line(line)
                appended.append(line)
        except BaseException as e:  # noqa: BLE001
            appender_errors.append(e)

    t = threading.Thread(target=appender, daemon=True)

    try:
        t.start()
        started.wait(timeout=2.0)
        # Let the appender land a few lines so we know the path is
        # warm before we start contesting the lock.
        time.sleep(0.05)

        # Run several snapshot → mutate → restore cycles, each one
        # under the sidecar lock. Each cycle uses `_atomic_write_bytes`
        # for the mutate (the most adversarial case: changes the inode
        # — pre-fix this is exactly how lines went missing).
        cycles = 5
        for _ in range(cycles):
            with kernel.hits_exclusive_lock():
                snapshot = HITS.read_bytes()
                # Mutate to something visibly different (extra trailer
                # line). A sibling _append_line that slipped through
                # would land on the post-mutate inode and be lost when
                # we restore — but it can't slip through because it's
                # blocked on the same sidecar lock.
                tampered = snapshot + b"INJECTED_TAMPER_LINE\n"
                _atomic_write_bytes(HITS, tampered)
                # Hold the lock briefly so the appender thread actually
                # contests it (otherwise the race window is too small
                # to be a real test of the serialization).
                time.sleep(0.02)
                # Restore. After this the file content matches the
                # checkpoint that was current at snapshot time, so the
                # appender's next `_verify_checkpoint` call inside
                # `_append_line` will pass.
                _atomic_write_bytes(HITS, snapshot)
            # Yield outside the lock so the appender can make progress
            # between cycles.
            time.sleep(0.02)

        # Wait for the appender to finish all its writes.
        t.join(timeout=10.0)
        assert not t.is_alive(), "appender thread did not finish in time"
        assert not appender_errors, (
            f"appender thread raised: {appender_errors!r}"
        )
        assert len(appended) == appender_count, (
            f"appender wrote {len(appended)} lines, expected "
            f"{appender_count}"
        )

        # The whole point of task #59: every line the appender thinks
        # it wrote must actually be in hits.txt. Pre-fix, some would
        # have been silently overwritten by `_atomic_write_bytes(HITS,
        # snapshot)` during a tamper cycle.
        final_text = HITS.read_text(encoding="utf-8")
        missing = [line for line in appended if line not in final_text]
        assert not missing, (
            f"{len(missing)} appended line(s) were lost across the "
            f"snapshot/restore cycles; first missing: {missing[:3]!r}"
        )
        # And the tamper trailer must NOT be present — restore worked.
        assert "INJECTED_TAMPER_LINE" not in final_text

    finally:
        stop.set()
        t.join(timeout=5.0)
        # Strip the appender lines back out so we leave the canonical
        # ledger pristine for downstream tests / commits. Use the lock
        # one more time so any straggling appender writes are visible.
        with kernel.hits_exclusive_lock():
            HITS.write_bytes(original_bytes)
            CHECKPOINT.write_bytes(original_cp)


# ---------- at-rest ledger integrity guard (task #53) ----------

def _run_integrity_check() -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(INTEGRITY_SCRIPT)],
        capture_output=True,
        text=True,
    )


def test_unmodified_hits_passes_integrity_check(fresh_checkpoint):
    r = _run_integrity_check()
    assert r.returncode == 0, (
        f"integrity check failed on pristine hits.txt:\n"
        f"stdout={r.stdout!r}\nstderr={r.stderr!r}"
    )
    assert "ledger integrity verified" in r.stdout


def test_truncated_hits_fails_integrity_check(hits_backup, fresh_checkpoint):
    """The whole point of task #53: a stray `HITS.write_text("")` or
    `> data/hits.txt` that wipes the body but happens to preserve the
    9-line preamble must be caught loudly. The Genesis-seal check
    alone would pass on a preamble-only file; the integrity check
    must not."""
    # Keep the Genesis preamble (lines 1-9 plus marker) so the seal
    # check would still pass — this isolates the integrity guard.
    text = hits_backup.decode("utf-8")
    lines = text.split("\n")
    marker_idx = lines.index(SEAL_MARKER)
    preamble_only = "\n".join(lines[: marker_idx + 1]) + "\n"
    try:
        _atomic_write_bytes(HITS, preamble_only.encode("utf-8"))
        # Sanity: the seal check itself still passes on this truncated file.
        seal_r = _run_seal_check()
        assert seal_r.returncode == 0, (
            "precondition: preamble-only file should pass the seal check; "
            "otherwise this test isn't exercising the right gap."
        )
        # The integrity check must catch it.
        r = _run_integrity_check()
        assert r.returncode != 0, (
            "integrity check must reject a ledger truncated to the preamble"
        )
        combined = r.stderr + r.stdout
        assert "SHRUNK" in combined or "TRUNCATION" in combined, combined
    finally:
        _atomic_write_bytes(HITS, hits_backup)


def test_in_place_rewrite_fails_integrity_check(hits_backup, fresh_checkpoint):
    """An in-place rewrite that keeps the file size identical but flips
    a byte deep in the body (past the preamble) is also a violation of
    the append-only invariant. The Genesis seal would not see it
    (preamble untouched), so the integrity guard must."""
    text = hits_backup.decode("utf-8")
    lines = text.split("\n")
    marker_idx = lines.index(SEAL_MARKER)
    # Flip a single character somewhere well past the preamble.
    victim = marker_idx + 50
    assert victim < len(lines), "ledger should have plenty of probe lines"
    original_line = lines[victim]
    assert len(original_line) > 0
    # Replace a character with another printable character of the same
    # length so the file size is byte-for-byte preserved.
    flipped = original_line[:-1] + ("X" if original_line[-1] != "X" else "Y")
    lines[victim] = flipped
    tampered = "\n".join(lines).encode("utf-8")
    assert len(tampered) == len(hits_backup), "size must match for this test"
    try:
        _atomic_write_bytes(HITS, tampered)
        r = _run_integrity_check()
        assert r.returncode != 0, (
            "integrity check must reject an in-place body rewrite"
        )
        assert "rewritten in place" in (r.stderr + r.stdout)
    finally:
        _atomic_write_bytes(HITS, hits_backup)


# ---------- repo lint: forbid non-append opens of data/hits.txt ----------

# Allowlisted files that legitimately mutate hits.txt or its checkpoint.
# Anything else matching the forbidden patterns is a regression.
_LEDGER_WRITE_ALLOWLIST = frozenset({
    "kernel.py",                     # _append_line (mode "a") + _update_checkpoint
    # BIRTH event append (mode "ab"): runs under
    # `kernel.hits_exclusive_lock()` for its full read-verify-append-
    # checkpoint window and delegates the checkpoint refresh to
    # `kernel._update_checkpoint`, so it serializes against
    # `kernel._append_line` writers (task #65).
    "scripts/seal-birth.py",
    "scripts/check-ledger-integrity.py",  # reads only, but mentions patterns
    "tests/test_morningstar.py",     # this lint test itself + tamper fixtures
})

# Directories to skip during the walk.
_LEDGER_LINT_SKIP_DIRS = frozenset({
    ".git", "node_modules", "__pycache__", ".local", ".cache",
    "attached_assets", "lean-proof", ".pnpm-store", "dist", "build",
    ".replit-artifact", ".pytest_cache",
})

# Regexes for forbidden ways to clobber data/hits.txt. Each pattern is
# tagged with a short reason so a failure tells the developer exactly
# what to do instead.
_LEDGER_LINT_PATTERNS: list[tuple[str, str]] = [
    # Python: any open(...) on hits.txt with a 'w'/'wb'/'w+' mode.
    (
        r"""open\([^)]*hits\.txt[^)]*['"]w[b+]?['"]""",
        "open(...hits.txt..., 'w'/'wb') truncates the ledger; use 'a'/'ab' "
        "(append) and route through kernel._append_line.",
    ),
    # Python: Path.write_text / write_bytes on the ledger handle.
    (
        r"""HITS\.write_(text|bytes)\(""",
        "HITS.write_text/write_bytes truncates the ledger; route appends "
        "through kernel._append_line.",
    ),
    (
        r"""LEDGER\.write_(text|bytes)\(""",
        "LEDGER.write_text/write_bytes truncates the ledger; route appends "
        "through kernel._append_line or scripts/seal-birth.py.",
    ),
    # Shell: `> data/hits.txt` or `>data/hits.txt` redirects.
    (
        r"""(?<![>])>\s*data/hits\.txt\b""",
        "shell redirect `> data/hits.txt` truncates the ledger; use `>>` "
        "only via kernel._append_line, never from a script.",
    ),
]


def _iter_repo_text_files():
    import re as _r

    skip_re = _r.compile(r"(^|/)(" + "|".join(_LEDGER_LINT_SKIP_DIRS) + r")(/|$)")
    # Only Python and shell touch the on-disk Python ledger; the React
    # frontend reads via the API and never opens data/hits.txt directly.
    # Narrowing to these suffixes avoids JSX false positives like
    # `<code>data/hits.txt</code>`, where the closing `>` of a tag
    # would otherwise look like a shell redirect.
    suffixes = {".py", ".sh", ".bash"}
    for path in REPO_ROOT.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(REPO_ROOT).as_posix()
        if skip_re.search(rel):
            continue
        if path.suffix not in suffixes:
            continue
        yield path, rel


def test_no_non_append_writes_to_hits_txt():
    """Lint guard for task #53: any new call site that opens
    data/hits.txt in a truncating mode (open 'w', Path.write_text/bytes,
    shell `> data/hits.txt`) outside the small allowlist is a
    regression. The 20k-line ledger has been wiped at least once by
    exactly this class of bug (see task #52 race-reproduction). If you
    have a legitimate reason to add a new appender, route it through
    kernel._append_line and add the file to _LEDGER_WRITE_ALLOWLIST."""
    import re as _r

    compiled = [(re_pat, _r.compile(re_pat), reason)
                for (re_pat, reason) in _LEDGER_LINT_PATTERNS]
    violations: list[str] = []
    for path, rel in _iter_repo_text_files():
        if rel in _LEDGER_WRITE_ALLOWLIST:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for _re_pat, rx, reason in compiled:
            for m in rx.finditer(text):
                line_no = text.count("\n", 0, m.start()) + 1
                violations.append(
                    f"{rel}:{line_no}: {m.group(0)!r} — {reason}"
                )
    assert not violations, (
        "Forbidden non-append write to data/hits.txt detected. The ledger "
        "is append-only; truncating writes have wiped it before. "
        "Either route through kernel._append_line or, if this is a "
        "deliberate maintenance script, add the file path to "
        "_LEDGER_WRITE_ALLOWLIST in tests/test_morningstar.py.\n  "
        + "\n  ".join(violations)
    )


# ---------- kernel.probe must abort on tampered Genesis ----------

def test_probe_refuses_to_append_when_body_truncated(hits_backup, fresh_checkpoint):
    """Task #57: an in-process integrity guard must abort an append
    when the at-rest checkpoint says the ledger has been body-truncated
    (preamble kept, probe lines wiped). The Genesis seal alone would
    PASS on a preamble-only file, so the long-running workflows
    (`zeta-burst-101-10000`, `zeta-sieve-14159-100000`) would happily
    keep appending to a truncated ledger until the next `post-merge.sh`
    run. The checkpoint check inside `_append_line` (added in task #57)
    must catch it on the very next probe.
    """
    import kernel

    # Truncate hits.txt to the 9-line Genesis preamble + marker only,
    # exactly the failure mode task #53 was created to catch.
    text = hits_backup.decode("utf-8")
    lines = text.split("\n")
    marker_idx = lines.index(SEAL_MARKER)
    preamble_only = "\n".join(lines[: marker_idx + 1]) + "\n"
    _atomic_write_bytes(HITS, preamble_only.encode("utf-8"))

    # Sanity: Genesis seal still verifies on the preamble-only file —
    # the integrity guard is the only thing that can catch this.
    kernel._verify_seal()

    size_before = HITS.stat().st_size

    with pytest.raises(RuntimeError, match="Ledger integrity check failed"):
        kernel.probe(1, 1, 0.5, 0.0)

    size_after = HITS.stat().st_size
    assert size_after == size_before, (
        "probe must not append to a body-truncated hits.txt; "
        f"size grew from {size_before} to {size_after}"
    )


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
