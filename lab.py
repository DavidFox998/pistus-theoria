"""Layer 7 (Application) — MorningStar-Lab REPL/CLI.

Usage:
  python lab.py                                          # banner + interactive REPL
  python lab.py -c "probe(1,19,0.5,0)"                   # one-shot probe
  python lab.py -c "zero(1)"                             # log the 1st Riemann zero
  python lab.py -c "hunt_zeros(1,3)"                     # log zeros 1..3
  python lab.py -c "bracket_zero(1,1e-4)"                # tight bracket sweep
  python lab.py -c "scan_critical_line(1,14,22,0.01)"    # sweep critical line
  python lab.py -c "scan_line(1,14,22,0.01,1)"           # sweep with explicit h
  python lab.py -c "scan_plane(1,1,0.4,0.6,14,22,0.1)"   # 2D plane sweep

REPL forms (interactive):
  probe h N re_s im_s
  zero n
  hunt_zeros n_start n_end
  bracket_zero n window
  scan_critical_line N im_start im_end [step]
  scan_line N im_start im_end step h
  scan_plane h N re_min re_max im_min im_max grid
"""

from __future__ import annotations

import argparse
import json
import re
import sys

import kernel

BANNER = (
    "MorningStar-Lab 4D Ready. Axes: W=h Z=N X=Re Y=Im\n"
    "commands: probe | zero | hunt_zeros | bracket_zero | "
    "scan_critical_line | scan_line | scan_plane"
)


def _split_args(rest: str) -> list[str]:
    rest = rest.strip()
    if rest.startswith("(") and rest.endswith(")"):
        rest = rest[1:-1]
    return [p for p in re.split(r"[,\s]+", rest) if p]


def _parse_probe(expr: str) -> tuple[int, int, float, float]:
    """Parse 'probe(h,N,re,im)' or 'probe h N re im'."""
    s = expr.strip()
    if not s.startswith("probe"):
        raise ValueError(f"unknown command: {expr!r}")
    parts = _split_args(s[len("probe") :])
    if len(parts) != 4:
        raise ValueError(f"probe needs 4 args (h N re_s im_s); got {len(parts)}")
    h, N, re_s, im_s = parts
    return int(h), int(N), float(re_s), float(im_s)


def _parse_zero(expr: str) -> int:
    """Parse 'zero(n)' or 'zero n'."""
    parts = _split_args(expr.strip()[len("zero") :])
    if len(parts) != 1:
        raise ValueError(f"zero needs 1 arg (n); got {len(parts)}")
    return int(parts[0])


def _parse_args(expr: str, head: str, n: int) -> list[str]:
    parts = _split_args(expr.strip()[len(head) :])
    if len(parts) != n:
        raise ValueError(f"{head} needs {n} args; got {len(parts)}")
    return parts


def _parse_scan(expr: str) -> tuple[int, float, float, float]:
    parts = _split_args(expr.strip()[len("scan_critical_line") :])
    if len(parts) not in (3, 4):
        raise ValueError(
            f"scan_critical_line needs 3 or 4 args (N im_start im_end [step]); got {len(parts)}"
        )
    N = int(parts[0])
    im_start = float(parts[1])
    im_end = float(parts[2])
    step = float(parts[3]) if len(parts) == 4 else 0.01
    return N, im_start, im_end, step


def _format_result(out: dict) -> str:
    pretty = {k: v for k, v in out.items() if k != "ledger_line"}
    rendered = json.dumps(pretty, sort_keys=True, indent=2)
    if "ledger_line" in out:
        return rendered + "\n  ledger: " + out["ledger_line"]
    return rendered


def _short_sha(sha: str) -> str:
    return sha[:8] if sha else "?"


def run_one(expr: str) -> int:
    s = expr.strip()
    # Order matters: longer prefixes first so e.g. 'scan_critical_line'
    # is matched before 'scan_line', and 'scan_line' before 'scan_plane'
    # never collides with anything else.
    if s.startswith("scan_critical_line"):
        N, im_start, im_end, step = _parse_scan(s)
        hits = kernel.scan_critical_line(N, im_start, im_end, step)
        for h_ in hits:
            l_abs = h_.get("L_abs") or "NA"
            print(f"HIT: t={h_['t']:.6f} |L|={l_abs} sha={_short_sha(h_['sha'])}")
        print(
            f"-- {len(hits)} hit(s) over t ∈ [{im_start}, {im_end}] step={step} "
            f"(N={N}, all probes appended to data/hits.txt)"
        )
        return 0
    if s.startswith("scan_line"):
        N, im_start, im_end, step, h = _parse_args(s, "scan_line", 5)
        zeros = kernel.scan_critical_line(
            int(N), float(im_start), float(im_end), float(step), int(h)
        )
        print(json.dumps({"zeros": zeros, "count": len(zeros)}, indent=2, default=str))
        return 0
    if s.startswith("scan_plane"):
        h, N, re_min, re_max, im_min, im_max, grid = _parse_args(s, "scan_plane", 7)
        summary = kernel.scan_plane(
            int(h),
            int(N),
            float(re_min),
            float(re_max),
            float(im_min),
            float(im_max),
            float(grid),
        )
        print(json.dumps(summary, indent=2))
        return 0
    if s.startswith("hunt_zeros"):
        n_start, n_end = _parse_args(s, "hunt_zeros", 2)
        hits = kernel.hunt_zeros(int(n_start), int(n_end))
        print(json.dumps({"count": len(hits)}, indent=2))
        return 0
    if s.startswith("bracket_zero"):
        n, window = _parse_args(s, "bracket_zero", 2)
        out = kernel.bracket_zero(int(n), float(window))
        print(json.dumps(out, indent=2, default=str))
        return 0
    if s.startswith("zero"):
        n = _parse_zero(s)
        out = kernel.zero(n)
        print(f"zero({n}) → 0.5 + {out['gamma']}i")
        print(_format_result(out))
        return 0
    if s.startswith("probe"):
        h, N, re_s, im_s = _parse_probe(s)
        out = kernel.probe(h, N, re_s, im_s)
        print(_format_result(out))
        return 0
    raise ValueError(f"unknown command: {expr!r}")


def repl() -> int:
    print(BANNER)
    print("type a command or 'quit'")
    while True:
        try:
            line = input("> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return 0
        if not line:
            continue
        if line in ("quit", "exit"):
            return 0
        try:
            run_one(line)
        except Exception as e:  # noqa: BLE001
            print(f"error: {e}", file=sys.stderr)


def main() -> int:
    ap = argparse.ArgumentParser(prog="lab.py")
    ap.add_argument(
        "-c",
        "--command",
        help=(
            "one-shot command (probe / zero / hunt_zeros / bracket_zero / "
            "scan_critical_line / scan_line / scan_plane)"
        ),
    )
    args = ap.parse_args()
    if args.command:
        return run_one(args.command)
    return repl()


if __name__ == "__main__":
    sys.exit(main())
