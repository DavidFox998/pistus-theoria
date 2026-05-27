#!/usr/bin/env python3
"""Re-roll ``data/hits.txt.checkpoint`` to cover the current ledger
prefix.

Task #127. Held under ``kernel.hits_exclusive_lock()`` for the full
read-and-rewrite window so a concurrent ``_append_line`` writer cannot
slip a line in between the file-hash and the atomic ``os.replace`` of
the checkpoint sidecar (same reentrant lock the tamper fixture uses,
see ``kernel._HitsLock``).

Before re-rolling we re-verify the *existing* checkpoint against the
live file. If the current sealed prefix is already broken (truncation
or in-place rewrite of bytes the checkpoint covers), we REFUSE to
re-roll — the operator would otherwise rubber-stamp a tampered file as
the new known-good prefix and silently shrink tamper coverage to zero.

Exit codes (stable contract used by ``/api/ledger/checkpoint/reroll``):

* ``0`` — checkpoint re-rolled. ``OK: ...`` line on stdout.
* ``2`` — current ledger fails ``_verify_checkpoint``. Stderr carries
  the ``LedgerIntegrityError`` message; the checkpoint is left
  untouched.
* ``1`` — anything else (kernel import failure, I/O error, etc.).
"""

from __future__ import annotations

import pathlib
import sys
import traceback


def main() -> int:
    repo_root = pathlib.Path(__file__).resolve().parent.parent
    if str(repo_root) not in sys.path:
        sys.path.insert(0, str(repo_root))

    try:
        import kernel
    except Exception as exc:  # pragma: no cover - import-time guard
        print(f"FATAL: failed to import kernel: {exc}", file=sys.stderr)
        traceback.print_exc()
        return 1

    try:
        with kernel.hits_exclusive_lock():
            try:
                kernel._verify_checkpoint()
            except kernel.LedgerIntegrityError as exc:
                print(
                    "REFUSE: existing checkpoint fails verification "
                    f"({exc}). Refusing to overwrite a sealed prefix "
                    "that already disagrees with the live ledger — "
                    "fix the tamper incident first.",
                    file=sys.stderr,
                )
                return 2

            before_size: int | None = None
            try:
                before_size = kernel.HITS.stat().st_size
            except OSError:
                pass

            kernel._update_checkpoint()

            after_size: int | None = None
            try:
                after_size = kernel.HITS.stat().st_size
            except OSError:
                pass

            print(
                "OK: checkpoint re-rolled "
                f"(before={before_size}, after={after_size}) "
                f"checkpoint={kernel.CHECKPOINT}"
            )
            return 0
    except Exception as exc:
        print(f"FATAL: re-roll failed: {exc}", file=sys.stderr)
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
