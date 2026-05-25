"""Layer 4 (Transport) — MorningStar-Lab kernel.

probe(h, N, re_s, im_s) -> dict.

Backend: mpmath (pure-Python arbitrary-precision). What we can actually
compute honestly:

- h == 1, N == 1: Riemann zeta ζ(s). Tag MPMATH_ZETA.
- h == 1, N > 1: principal Dirichlet character χ₀ mod N. We strip the
  Euler factors at primes p|N from ζ(s):
      L(s, χ₀) = ζ(s) · ∏_{p|N} (1 - p^{-s}).
  Tag MPMATH_DIRICHLET_TRIVIAL.
- h >= 2: class-group / modular L-functions are out of scope for the
  mpmath backend. The line is tagged NEEDS_SAGE and L_nonvanish is left
  as a stub (True) — the tag is the contract that says "do not trust
  this number".

Failure modes (overflow, mpmath exception, timeout-by-exception) also
fall back to NEEDS_SAGE with a reason field; the ledger never silently
lies about a backend result.

Append-only invariant: before any write, this module shells out to
scripts/check-genesis-seal.py and refuses to proceed if the Genesis
preamble of data/hits.txt has been altered.
"""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

import mpmath

REPO_ROOT = Path(__file__).resolve().parent
HITS = REPO_ROOT / "data" / "hits.txt"
SEAL_CHECK = REPO_ROOT / "scripts" / "check-genesis-seal.py"

BACKEND = "mpmath"
BACKEND_VERSION = mpmath.__version__
NONVANISH_TOL = mpmath.mpf("1e-10")
# Honest-scope zero-witness tolerance for RH_ok=True. Tighter than the
# nonvanish threshold so the two predicates don't both fire on borderline
# values: RH_ok is only True when we have actually pinned a zero
# (|ζ| < 1e-12) on the critical line with the real ζ backend.
ZERO_WITNESS_TOL = mpmath.mpf("1e-12")
# Back-compat alias for the older HEAD name.
RH_VANISH_TOL = ZERO_WITNESS_TOL


def _kms_beta(re_s: float) -> float | None:
    """Bost–Connes inverse-temperature β = 1/Re(s). At Re(s)=0.5 the
    physical phase transition fires at β=2 — this is the live KMS
    surface from M13 piped into the ledger. None at Re(s)=0."""
    if re_s == 0.0:
        return None
    return 1.0 / float(re_s)


# Public alias retained for callers from the older `hunt_zeros`/`scan_plane`
# surface; same semantics as the underscore helper.
kms_beta = _kms_beta


def _rh_ok(re_s: float, tag: str, L_abs: str | None) -> bool:
    """Honest-scope RH witness.

    RH_ok is True iff we actually observed |L(s)| below the zero-
    witness tolerance on the critical line, using the real Riemann ζ
    backend. Anything else — off-line, wrong backend (Dirichlet, no
    backend), NEEDS_SAGE stub, missing |L| — is False. The gunsight
    must know when it misses.
    """
    if tag != "MPMATH_ZETA":
        return False
    if re_s != 0.5:
        return False
    if L_abs is None:
        return False
    try:
        return mpmath.mpf(L_abs) < ZERO_WITNESS_TOL
    except (TypeError, ValueError):
        return False


def _verify_seal() -> None:
    """Run check-genesis-seal.py; raise if it fails."""
    result = subprocess.run(
        [sys.executable, str(SEAL_CHECK)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Genesis seal verification failed (exit {result.returncode}):\n"
            f"{result.stderr.strip() or result.stdout.strip()}"
        )


def _append_line(line: str) -> None:
    """Append exactly one line + newline to hits.txt and fsync."""
    HITS.parent.mkdir(parents=True, exist_ok=True)
    with HITS.open("a", encoding="utf-8") as f:
        f.write(line + "\n")
        f.flush()
        os.fsync(f.fileno())


def _prime_divisors(n: int) -> list[int]:
    """Distinct prime divisors of |n|, n != 0. Trial division is fine
    for the modest N used by the lab."""
    n = abs(int(n))
    if n <= 1:
        return []
    primes: list[int] = []
    d = 2
    while d * d <= n:
        if n % d == 0:
            primes.append(d)
            while n % d == 0:
                n //= d
        d += 1 if d == 2 else 2
    if n > 1:
        primes.append(n)
    return primes


def _evaluate(h: int, N: int, re_s: float, im_s: float) -> dict[str, Any]:
    """Return the backend result dict, with keys:
        tag: str           — MPMATH_ZETA | MPMATH_DIRICHLET_TRIVIAL | NEEDS_SAGE
        backend: str       — "mpmath" or "none"
        L_real, L_imag: str (or None for NEEDS_SAGE)
        L_abs: str (or None)
        L_nonvanish: bool
        reason: str (only present when tag == NEEDS_SAGE)
    """
    s = mpmath.mpc(re_s, im_s)

    if h == 1 and N == 1:
        try:
            with mpmath.workdps(50):
                val = mpmath.zeta(s)
                absval = abs(val)
            return {
                "tag": "MPMATH_ZETA",
                "backend": BACKEND,
                "L_real": mpmath.nstr(val.real, 20),
                "L_imag": mpmath.nstr(val.imag, 20),
                "L_abs": mpmath.nstr(absval, 20),
                "L_nonvanish": bool(absval > NONVANISH_TOL),
            }
        except Exception as e:  # noqa: BLE001
            return {
                "tag": "NEEDS_SAGE",
                "backend": "none",
                "L_real": None,
                "L_imag": None,
                "L_abs": None,
                "L_nonvanish": True,
                "reason": f"mpmath_zeta_failed:{type(e).__name__}",
            }

    if h == 1 and N > 1:
        try:
            with mpmath.workdps(50):
                val = mpmath.zeta(s)
                for p in _prime_divisors(N):
                    val = val * (mpmath.mpc(1) - mpmath.power(p, -s))
                absval = abs(val)
            return {
                "tag": "MPMATH_DIRICHLET_TRIVIAL",
                "backend": BACKEND,
                "L_real": mpmath.nstr(val.real, 20),
                "L_imag": mpmath.nstr(val.imag, 20),
                "L_abs": mpmath.nstr(absval, 20),
                "L_nonvanish": bool(absval > NONVANISH_TOL),
            }
        except Exception as e:  # noqa: BLE001
            return {
                "tag": "NEEDS_SAGE",
                "backend": "none",
                "L_real": None,
                "L_imag": None,
                "L_abs": None,
                "L_nonvanish": True,
                "reason": f"mpmath_dirichlet_trivial_failed:{type(e).__name__}",
            }

    return {
        "tag": "NEEDS_SAGE",
        "backend": "none",
        "L_real": None,
        "L_imag": None,
        "L_abs": None,
        "L_nonvanish": True,
        "reason": "h>=2_out_of_scope_for_mpmath_backend",
    }


def probe(h: int, N: int, re_s: float, im_s: float) -> dict[str, Any]:
    """Run a single 4D probe and append exactly one ledger line.

    Returns a dict with keys: h, N, L_nonvanish, RH_ok, kms_beta, tag,
    backend, L_real, L_imag, L_abs, sha, ledger_line. The `reason` key
    is only present when the backend was not able to evaluate
    (tag NEEDS_SAGE).
    """
    _verify_seal()

    ts = time.time_ns()
    inputs = {"h": int(h), "N": int(N), "re_s": float(re_s), "im_s": float(im_s)}

    ev = _evaluate(inputs["h"], inputs["N"], inputs["re_s"], inputs["im_s"])

    kms = _kms_beta(inputs["re_s"])
    output = {
        "h": inputs["h"],
        "N": inputs["N"],
        "L_nonvanish": ev["L_nonvanish"],
        "RH_ok": _rh_ok(inputs["re_s"], ev["tag"], ev["L_abs"]),
        "kms_beta": kms,
        "tag": ev["tag"],
        "backend": ev["backend"],
        "L_real": ev["L_real"],
        "L_imag": ev["L_imag"],
        "L_abs": ev["L_abs"],
    }
    if "reason" in ev:
        output["reason"] = ev["reason"]

    digest_payload = {"ts": ts, "in": inputs, "out": output, "tag": ev["tag"]}
    body = json.dumps(digest_payload, sort_keys=True, separators=(",", ":"))
    sha = hashlib.sha256(body.encode("utf-8")).hexdigest()

    L_abs_field = ev["L_abs"] if ev["L_abs"] is not None else "NA"
    reason_field = f" reason={ev['reason']}" if "reason" in ev else ""
    kms_field = "NA" if kms is None else repr(kms)
    ledger_line = (
        f"probe ts={ts} h={inputs['h']} N={inputs['N']} "
        f"re={inputs['re_s']} im={inputs['im_s']} "
        f"L_nonvanish={output['L_nonvanish']} RH_ok={output['RH_ok']} "
        f"kms_beta={kms_field} "
        f"{ev['tag']} L_abs={L_abs_field}{reason_field} sha={sha}"
    )
    _append_line(ledger_line)

    return {**output, "sha": sha, "ledger_line": ledger_line}


def zero(n: int) -> dict[str, Any]:
    """Compute the n-th nontrivial Riemann zero via mpmath.zetazero and
    log a probe at (Re=0.5, Im=γ_n).

    Returns the probe result dict with two extra keys:
      - `gamma`: γ_n as a 20-digit mpmath nstr (current preferred name)
      - `zero_im_mpmath`: alias for `gamma` (back-compat with the older
        HEAD `hunt_zeros`/`bracket_zero` surface)
      - `n`: the input ordinal

    Float64 rounding of the imaginary part means |ζ| at the probed
    point is typically ~1e-15 rather than 0 — small enough that the
    ZERO_WITNESS_TOL gunsight fires, large enough to be honest about
    the precision loss. Honest scope: mpmath, not a Lean-verified
    statement.
    """
    nn = int(n)
    if nn < 1:
        raise ValueError("zero(n) requires n >= 1")
    with mpmath.workdps(50):
        z = mpmath.zetazero(nn)
        gamma_str = mpmath.nstr(z.imag, 20)
        gamma_f = float(z.imag)
    result = probe(1, 1, 0.5, gamma_f)
    return {
        "n": nn,
        "gamma": gamma_str,
        "zero_im_mpmath": gamma_str,
        **result,
    }


def hunt_zeros(n_start: int = 1, n_end: int = 10) -> list[dict[str, Any]]:
    """Log the n_start..n_end nontrivial ζ zeros via repeated zero(n) calls.

    Each call probes at the zero (so every entry has its own ledger
    line + SHA). Prints a one-line summary per zero.
    """
    if int(n_start) < 1 or int(n_end) < int(n_start):
        raise ValueError("hunt_zeros: require 1 <= n_start <= n_end")
    hits: list[dict[str, Any]] = []
    for n in range(int(n_start), int(n_end) + 1):
        r = zero(n)
        hits.append(r)
        print(
            f"ZERO {n}: t={r['zero_im_mpmath']} "
            f"|L|={r['L_abs']} beta={r['kms_beta']} "
            f"RH_ok={r['RH_ok']} sha={r['sha'][:16]}"
        )
    return hits


def bracket_zero(n: int, window: float = 1e-6) -> dict[str, Any]:
    """Tight critical-line sweep around the n-th ζ zero.

    Calls scan_critical_line over [t0-window, t0+window] with step
    window/5. Note that scan_critical_line uses float steps, so the
    sweep typically won't actually land within ZERO_WITNESS_TOL (1e-12)
    of t0 — call zero(n) separately if you want the exact zero logged.
    The sweep does show |L| dipping toward the zero in the L_abs
    field of each probed ledger line, which is the "radar coverage"
    receipt the bracket exists to produce.
    """
    if int(n) < 1:
        raise ValueError("bracket_zero: n must be >= 1")
    if window <= 0:
        raise ValueError("bracket_zero: window must be > 0")
    with mpmath.workdps(50):
        t0 = float(mpmath.zetazero(int(n)).imag)
    step = window / 5.0
    scan = scan_critical_line(1, t0 - window, t0 + window, step, 1)
    return {
        "n": int(n),
        "t0": t0,
        "window": window,
        "step": step,
        "zeros_found": scan,
        "zeros_count": len(scan),
    }


def scan_critical_line(
    N: int,
    im_start: float,
    im_end: float,
    step: float = 0.01,
    h: int = 1,
) -> list[dict[str, Any]]:
    """Sweep the critical line Re(s) = 0.5 for L-function (h, N).

    Every grid point is probed and appended to data/hits.txt (so the
    sweep is fully audit-trailed). Points where the honest-scope
    gunsight fires (RH_ok=True, i.e. tag=MPMATH_ZETA AND
    |ζ| < ZERO_WITNESS_TOL on the critical line) are returned as
    "zero hits".

    Honest scope: a fixed-step sweep almost never lands within
    ZERO_WITNESS_TOL (1e-12) of an actual zero, so this function will
    typically return []. It is a coverage tool, not a zero finder —
    use `kernel.zero(n)` (mpmath.zetazero) for actual zeros.
    """
    if step <= 0:
        raise ValueError("scan_critical_line: step must be > 0")
    if im_end < im_start:
        raise ValueError("scan_critical_line: im_end must be >= im_start")
    NN = int(N)
    hh = int(h)
    start = float(im_start)
    end = float(im_end)
    delta = float(step)
    hits: list[dict[str, Any]] = []
    i = 0
    while True:
        t = start + i * delta
        if t > end + 1e-12:
            break
        r = probe(hh, NN, 0.5, t)
        if r.get("RH_ok") is True:
            hits.append(
                {
                    "t": t,
                    "im": t,
                    "sha": r["sha"],
                    "L_abs": r.get("L_abs"),
                    "kms_beta": r.get("kms_beta"),
                    "tag": r.get("tag"),
                    "ledger_line": r["ledger_line"],
                }
            )
            print(
                f"ZERO: Im={t:.6f} sha={r['sha']} "
                f"kms_beta={r.get('kms_beta')} tag={r.get('tag')}"
            )
        i += 1
    return hits


def scan_plane(
    h: int,
    N: int,
    re_min: float,
    re_max: float,
    im_min: float,
    im_max: float,
    grid: float = 0.1,
    max_probes: int = 10000,
) -> dict[str, Any]:
    """Full 2D sweep of the (Re(s), Im(s)) rectangle for L-function (h, N).

    Every grid point is probed and appended to data/hits.txt. Useful
    for documenting that an entire region was inspected (off-line zero
    hunt, KMS-temperature region surveys, etc.).

    `max_probes` is a hard safety cap to keep the ledger from
    exploding; the function raises if the grid would exceed it.
    """
    if grid <= 0:
        raise ValueError("scan_plane: grid must be > 0")
    if re_max < re_min or im_max < im_min:
        raise ValueError("scan_plane: max must be >= min on both axes")
    n_re = int((re_max - re_min) / grid) + 1
    n_im = int((im_max - im_min) / grid) + 1
    n_total = n_re * n_im
    if n_total > max_probes:
        raise ValueError(
            f"scan_plane: would emit {n_total} probes (cap is {max_probes}); "
            "raise max_probes explicitly to proceed"
        )
    hits = 0
    for i in range(n_re):
        re_s = re_min + i * grid
        if re_s > re_max:
            break
        for j in range(n_im):
            im_s = im_min + j * grid
            if im_s > im_max:
                break
            out = probe(int(h), int(N), float(re_s), float(im_s))
            if out["RH_ok"] and not out["L_nonvanish"]:
                hits += 1
    return {"probed": n_total, "gunsight_hits": hits, "grid": grid}


if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("usage: kernel.py h N re_s im_s", file=sys.stderr)
        sys.exit(2)
    out = probe(int(sys.argv[1]), int(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4]))
    print(json.dumps(out, sort_keys=True))
