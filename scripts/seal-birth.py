#!/usr/bin/env python3
"""Append a single BIRTH event to data/hits.txt and re-verify the seal.

A BIRTH event records that a numerical reconnaissance certificate
PDF was compiled from a snapshot of the ledger. It is *not* a probe:
the line carries tag=BIRTH (never tag=MPMATH_ZETA / NEEDS_SAGE etc.)
so it can never be mistaken for an L-function evaluation.

Honest-scope guards:
  - Verifies the Genesis seal BEFORE writing. If the seal check fails
    we never append.
  - The body includes the SHA-256 of the compiled PDF, the line count
    of the ledger at write time, and a nanosecond timestamp. The
    per-line SHA is then computed over that body (same scheme as
    probe rows), so the BIRTH event is uniquely receipted and is
    itself part of the hash chain.
  - Verifies the Genesis seal AFTER writing. The seal only covers
    lines 1-9 (the preamble), but re-verifying after the append
    proves the helper didn't accidentally touch the preamble.

Concurrency (task #65):
  - The entire read-verify-append-checkpoint window runs under
    `kernel.hits_exclusive_lock()` (the sidecar
    `data/.hits.lock` flock, also held by `kernel._append_line`).
    This is the only other legitimate appender to `data/hits.txt`
    besides `_append_line`; routing it through the same lock means
    a stray re-run of the birth ceremony on a live ledger cannot
    interleave with a concurrent `kernel.probe()` writer or desync
    `data/hits.txt.checkpoint`.
  - The checkpoint refresh delegates to `kernel._update_checkpoint`
    so the on-disk shape (size + SHA-256, tmp + os.replace) stays
    in lockstep with the canonical writer.
"""
from __future__ import annotations

import hashlib
import pathlib
import subprocess
import sys
import time

REPO = pathlib.Path(__file__).resolve().parent.parent
LEDGER = REPO / "data" / "hits.txt"
PDF = REPO / "data" / "MorningStar_RH_Cert.pdf"
TEX = REPO / "data" / "MorningStar_RH_Cert.tex"
SEAL_CHECK = REPO / "scripts" / "check-genesis-seal.py"

NOTE = "100-zero MorningStar RH reconnaissance cert; axiom debt []; beta=2.0 uniform"

sys.path.insert(0, str(REPO))
import kernel  # noqa: E402  — must import after sys.path tweak


def _verify_seal(label: str) -> None:
    res = subprocess.run(
        [sys.executable, str(SEAL_CHECK)],
        capture_output=True,
        text=True,
        check=False,
    )
    if res.returncode != 0:
        sys.stderr.write(
            f"FATAL ({label}): Genesis seal verification failed:\n"
            f"{res.stdout}\n{res.stderr}\n"
        )
        sys.exit(2)
    sys.stdout.write(f"ok ({label}): {res.stdout.strip()}\n")


def main() -> int:
    if not PDF.exists():
        sys.stderr.write(
            f"FATAL: {PDF} not found. Run `cd data && pdflatex MorningStar_RH_Cert.tex` first.\n"
        )
        return 1
    if not TEX.exists():
        sys.stderr.write(f"FATAL: {TEX} not found.\n")
        return 1

    # Serialize the entire read-verify-append-checkpoint window against
    # any concurrent kernel._append_line writer (task #65).
    with kernel.hits_exclusive_lock():
        _verify_seal("pre-write")

        pdf_sha = hashlib.sha256(PDF.read_bytes()).hexdigest()
        tex_sha = hashlib.sha256(TEX.read_bytes()).hexdigest()
        ledger_lines_before = sum(1 for _ in LEDGER.open("rb"))
        ts = time.time_ns()

        body = (
            f"birth ts={ts} tag=BIRTH "
            f"cert_pdf_sha256={pdf_sha} "
            f"cert_tex_sha256={tex_sha} "
            f"ledger_lines_before={ledger_lines_before} "
            f'note="{NOTE}"'
        )
        line_sha = hashlib.sha256(body.encode("utf-8")).hexdigest()
        line = f"{body} sha={line_sha}\n"

        with LEDGER.open("ab") as fh:
            fh.write(line.encode("utf-8"))
            fh.flush()
            import os as _os
            _os.fsync(fh.fileno())

        # Refresh the at-rest checkpoint via the canonical writer so the
        # on-disk shape stays in lockstep with kernel._append_line.
        kernel._update_checkpoint()

        _verify_seal("post-write")

    sys.stdout.write(f"birth line appended:\n  {line.rstrip()}\n")
    sys.stdout.write(f"PDF sha256:    {pdf_sha}\n")
    sys.stdout.write(f"TeX sha256:    {tex_sha}\n")
    sys.stdout.write(f"BIRTH line sha: {line_sha}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
