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

Task #142. The script also prints ``STEP:`` and ``PROGRESS:`` lines on
stdout (one per phase, plus periodic byte-progress during the SHA-256
pass) so the streaming variant of the API endpoint can forward live
feedback to the dashboard instead of leaving the user with a frozen
spinner while ``data/hits.txt`` is hashed. Every print is flushed
immediately. The plain-text contract on the final ``OK: ...`` /
``REFUSE: ...`` / ``FATAL: ...`` lines is unchanged so the non-stream
endpoint still reads them verbatim.

Exit codes (stable contract used by ``/api/ledger/checkpoint/reroll``
and ``/api/ledger/checkpoint/reroll/stream``):

* ``0`` — checkpoint re-rolled. ``OK: ...`` line on stdout.
* ``2`` — current ledger fails ``_verify_checkpoint``. Stderr carries
  the ``LedgerIntegrityError`` message; the checkpoint is left
  untouched.
* ``1`` — anything else (kernel import failure, I/O error, etc.).
"""

from __future__ import annotations

import hashlib
import os
import pathlib
import sys
import traceback


def _say(message: str) -> None:
    """Print a progress line and flush so SSE forwarders see it immediately."""

    print(message, flush=True)


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
        _say("STEP: acquiring ledger lock")
        with kernel.hits_exclusive_lock():
            _say("STEP: verifying existing checkpoint")
            try:
                kernel._verify_checkpoint()
            except kernel.LedgerIntegrityError as exc:
                print(
                    "REFUSE: existing checkpoint fails verification "
                    f"({exc}). Refusing to overwrite a sealed prefix "
                    "that already disagrees with the live ledger — "
                    "fix the tamper incident first.",
                    file=sys.stderr,
                    flush=True,
                )
                return 2

            before_size: int | None = None
            try:
                before_size = kernel.HITS.stat().st_size
            except OSError:
                pass

            # Task #142: replicate kernel._update_checkpoint() inline so
            # we can stream byte-level hashing progress. The chunked
            # SHA-256 pass is functionally identical to the kernel's
            # `hashlib.sha256(HITS.read_bytes()).hexdigest()` — same
            # algorithm over the same bytes — but it never holds the
            # full ledger in memory at once and lets us emit progress.
            total = before_size if before_size is not None else 0
            _say(f"STEP: hashing prefix (size={total} bytes)")
            hasher = hashlib.sha256()
            hashed = 0
            chunk_size = 1024 * 1024  # 1 MiB
            # Progress cadence: at most ~20 PROGRESS lines for the
            # whole pass, regardless of file size, so a tiny ledger
            # doesn't drown the stream and a huge one still ticks.
            progress_step = max(chunk_size, (total // 20) or chunk_size)
            next_progress = progress_step
            with open(kernel.HITS, "rb") as fh:
                while True:
                    chunk = fh.read(chunk_size)
                    if not chunk:
                        break
                    hasher.update(chunk)
                    hashed += len(chunk)
                    if hashed >= next_progress or hashed == total:
                        pct = (
                            f" ({(hashed * 100) // total}%)" if total > 0 else ""
                        )
                        _say(f"PROGRESS: hashed {hashed}/{total} bytes{pct}")
                        next_progress += progress_step
            sha = hasher.hexdigest()
            after_size = hashed

            _say(f"STEP: writing checkpoint sha={sha[:12]}…")
            tmp = kernel.CHECKPOINT.with_name(kernel.CHECKPOINT.name + ".tmp")
            tmp.write_text(f"{after_size} {sha}\n", encoding="utf-8")
            os.replace(tmp, kernel.CHECKPOINT)

            print(
                "OK: checkpoint re-rolled "
                f"(before={before_size}, after={after_size}) "
                f"checkpoint={kernel.CHECKPOINT}",
                flush=True,
            )
            return 0
    except Exception as exc:
        print(f"FATAL: re-roll failed: {exc}", file=sys.stderr, flush=True)
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
