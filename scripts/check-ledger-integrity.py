#!/usr/bin/env python3
"""At-rest integrity guard for data/hits.txt.

Complements scripts/check-genesis-seal.py (which only covers the
9-line preamble). The Genesis seal cannot detect a stray
`HITS.write_text(...)` or `> data/hits.txt` that wipes the body of the
ledger, because such a rewrite either kills the preamble (caught by
the seal) OR keeps the preamble and silently drops 20k probe lines
(not caught by anything until the next probe fails). Task #53.

The companion file data/hits.txt.checkpoint stores "<size> <sha256>"
of the last known-good ledger state, updated atomically by
kernel._append_line and scripts/seal-birth.py after every legitimate
append. Because the ledger is strictly append-only, any legitimate
growth above `size` still validates against the recorded prefix SHA
— a stale checkpoint is safe; only a *shrunken* or *in-place
rewritten* file is a tamper.

Exits 0 if:
  - data/hits.txt.checkpoint exists and is well-formed,
  - the live ledger is at least as long as the checkpoint records,
  - SHA-256 of the live ledger's first `size` bytes matches the
    recorded hash,
  - the Genesis preamble seal still verifies (defence in depth).

Exits 2 on any of:
  - checkpoint missing or malformed,
  - live ledger shorter than checkpoint (TRUNCATION / REWRITE),
  - prefix-SHA mismatch (IN-PLACE REWRITE),
  - Genesis seal mismatch.

Recovery recipe lives in docs/REPRODUCE.md.
"""

from __future__ import annotations

import hashlib
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
HITS = REPO_ROOT / "data" / "hits.txt"
CHECKPOINT = REPO_ROOT / "data" / "hits.txt.checkpoint"
SEAL_CHECK = REPO_ROOT / "scripts" / "check-genesis-seal.py"


def _fire_alert(msg: str, failure_mode: str) -> None:
    """Best-effort: route the same alert that kernel._append_line fires
    when its in-process checkpoint check trips. Opt-in via the same env
    vars (MORNINGSTAR_ALERT_WEBHOOK_URL / MORNINGSTAR_ALERT_EMAIL_TO +
    MORNINGSTAR_ALERT_SMTP_HOST); a delivery failure cannot mask the
    exit code (task #63)."""
    try:
        if str(REPO_ROOT) not in sys.path:
            sys.path.insert(0, str(REPO_ROOT))
        import kernel  # noqa: PLC0415

        kernel._fire_ledger_alert(
            msg,
            {
                "failure_mode": failure_mode,
                "source": "scripts/check-ledger-integrity.py",
            },
        )
    except Exception as e:  # noqa: BLE001 - best-effort, never mask exit
        sys.stderr.write(f"WARN: ledger alert dispatch failed: {e}\n")


def _die(msg: str, failure_mode: str = "integrity_check_failed") -> "int":
    sys.stderr.write(f"FATAL: {msg}\n")
    sys.stderr.write(
        "  Recovery: see docs/REPRODUCE.md section "
        '"Recovering data/hits.txt from a tamper or accidental truncation".\n'
    )
    _fire_alert(msg, failure_mode)
    return 2


def main() -> int:
    if not HITS.exists():
        return _die(f"{HITS} missing.")
    if not CHECKPOINT.exists():
        return _die(
            f"{CHECKPOINT} missing — cannot verify at-rest integrity. "
            "This file is committed; restore it from git."
        )

    raw = CHECKPOINT.read_text(encoding="utf-8").strip()
    parts = raw.split()
    if len(parts) != 2:
        return _die(
            f"{CHECKPOINT} malformed (expected '<size> <sha256>', got {raw!r})."
        )
    try:
        expected_size = int(parts[0])
    except ValueError:
        return _die(f"{CHECKPOINT} size field not an integer: {parts[0]!r}.")
    expected_sha = parts[1].lower()
    if len(expected_sha) != 64 or any(c not in "0123456789abcdef" for c in expected_sha):
        return _die(f"{CHECKPOINT} sha256 field malformed: {expected_sha!r}.")

    data = HITS.read_bytes()
    actual_size = len(data)
    if actual_size < expected_size:
        return _die(
            f"{HITS} SHRUNK — expected at least {expected_size} bytes, "
            f"got {actual_size}. TRUNCATION or in-place rewrite suspected. "
            "DO NOT append anything before recovering — appends would lose "
            "data permanently."
        )

    prefix_sha = hashlib.sha256(data[:expected_size]).hexdigest()
    if prefix_sha != expected_sha:
        return _die(
            f"{HITS} first {expected_size} bytes have been rewritten in place. "
            f"  expected sha256: {expected_sha}\n"
            f"  got sha256:      {prefix_sha}\n"
            "The ledger is append-only; in-place edits are not permitted."
        )

    # Defence in depth: re-run the Genesis seal check.
    import importlib.util

    spec = importlib.util.spec_from_file_location("_seal_check", str(SEAL_CHECK))
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    if mod.compute_seal() != mod.EXPECTED_SEAL:
        return _die("Genesis seal mismatch (preamble tampered).")

    growth = actual_size - expected_size
    print(
        f"ok: ledger integrity verified "
        f"(checkpoint={expected_size}B, live={actual_size}B, growth=+{growth}B)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
