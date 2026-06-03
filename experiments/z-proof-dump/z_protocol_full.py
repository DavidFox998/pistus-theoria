#!/usr/bin/env python3
"""
Z_PROTOCOL_YM_FULL — three real, billed cold-LLM measurements via the Replit
Anthropic proxy. Logs EVERY output. Resumable (progress JSON) with a wall-clock
budget so each invocation stays under the shell cap; re-run until "ALL DONE".

Tests:
  1. DIGITS  : count digits of 1000000001119 (true=13). 100 trials, temperature 0.
  2. ZETA    : |zeta(0.5 + 14.134725 i)| (true via mpmath). 20 trials, temperature 0.
  3. BESSEL_T: estimate I_10(20.0) (true via mpmath) across temperatures
               {0,0.2,0.4,0.6,0.8,1.0}, 20 trials each.

HONEST: outputs recorded verbatim; unparseable -> counted, never back-filled.
At temperature 0 trials are deterministic (identical lines expected). The
"temperature" axis here is LLM sampling temperature (all LLM-direct, NO tool);
it is NOT the categorical T=1=tool-use axis.

Env: Z_MODEL (default claude-haiku-4-5), Z_BUDGET (default 85).
"""
import os, json, re, time, urllib.request, urllib.error
import mpmath as mp
from concurrent.futures import ThreadPoolExecutor, as_completed

mp.mp.dps = 50
HERE = os.path.dirname(os.path.abspath(__file__))
MODEL = os.environ.get("Z_MODEL", "claude-haiku-4-5")
BUDGET = float(os.environ.get("Z_BUDGET", "85"))
BASE = os.environ["AI_INTEGRATIONS_ANTHROPIC_BASE_URL"].rstrip("/")
KEY = os.environ["AI_INTEGRATIONS_ANTHROPIC_API_KEY"]
URL = BASE + "/v1/messages"
PROGRESS = os.path.join(HERE, "Z_PROTOCOL_FULL_progress.json")
NUM_RE = re.compile(r"[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?")
SUP = {ord(a): b for a, b in zip("\u2070\u00b9\u00b2\u00b3\u2074\u2075\u2076\u2077\u2078\u2079\u207b",
                                 "0123456789-")}
MUL10 = re.compile(r"[\u00d7xX\u2715\u22c5\u00b7*]\s*10\s*\^?\s*"
                   r"([\u207b\-]?[0-9\u2070\u00b9\u00b2\u00b3\u2074\u2075\u2076\u2077\u2078\u2079]+)")


def _normexp(m):
    return "e" + m.group(1).translate(SUP)


def extract_number(text):
    """Robust numeric extraction: handles ASCII e-notation AND unicode/caret
    'x10^n' forms (e.g. '4.563x10^7', '3.5x10\u2077'). Returns None if no number."""
    s = MUL10.sub(_normexp, text.replace(",", ""))
    m = NUM_RE.search(s)
    return float(m.group(0)) if m else None

DIGIT_N = "1000000001119"
DIGIT_TRUE = 13
BESSEL_TRUE = float(mp.besseli(10, 20))
ZETA_C = mp.zeta(mp.mpf("0.5") + mp.mpf("14.134725") * 1j)
ZETA_TRUE_ABS = float(abs(ZETA_C))

P_DIGIT = (f"How many digits are in the integer {DIGIT_N}? Do NOT use any tool, "
           "code, or step-by-step work. Output ONLY the integer count. One line.")
P_ZETA = ("Estimate the magnitude |zeta(0.5 + 14.134725 i)| of the Riemann zeta "
          "function at s = 0.5 + 14.134725 i. Do NOT use any tool or step-by-step "
          "work. Output ONLY a single decimal number. One line.")
P_BESSEL = ("Estimate I_10(20.0), the modified Bessel function of the first kind. "
            "Do NOT use any tool or step-by-step work. Output ONLY a number. One line.")


def call_once(prompt, temperature, max_tokens):
    body = json.dumps({"model": MODEL, "max_tokens": max_tokens,
                       "temperature": temperature,
                       "messages": [{"role": "user", "content": prompt}]}).encode()
    req = urllib.request.Request(URL, data=body, method="POST", headers={
        "x-api-key": KEY, "anthropic-version": "2023-06-01",
        "content-type": "application/json"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                data = json.load(r)
            text = "".join(p.get("text", "") for p in data.get("content", [])
                           if p.get("type") == "text").strip()
            val = extract_number(text)
            return {"raw": text, "value": val, "ok": val is not None}
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 3:
                time.sleep(2 ** attempt); continue
            detail = ""
            try:
                detail = e.read().decode()[:160]
            except Exception:
                pass
            return {"raw": f"HTTPError {e.code}: {detail}", "value": None, "ok": False}
        except Exception as e:  # noqa: BLE001
            if attempt < 3:
                time.sleep(2 ** attempt); continue
            return {"raw": f"ERR {type(e).__name__}", "value": None, "ok": False}
    return {"raw": "exhausted", "value": None, "ok": False}


def build_jobs():
    jobs = []
    for t in range(100):
        jobs.append(("DIGITS", P_DIGIT, 0.0, 8, t))
    for t in range(20):
        jobs.append(("ZETA", P_ZETA, 0.0, 16, t))
    for temp in [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]:
        for t in range(20):
            jobs.append((f"BESSEL_T{temp}", P_BESSEL, temp, 16, t))
    return jobs


def main():
    progress = {}
    if os.path.exists(PROGRESS):
        progress = json.load(open(PROGRESS))
    jobs = build_jobs()
    todo = [(test, p, temp, mt, t, f"{test}#{t}")
            for (test, p, temp, mt, t) in jobs if f"{test}#{t}" not in progress]
    total = len(jobs)
    if not todo:
        print(f"ALL DONE: {len(progress)}/{total}")
        finalize(progress)
        return

    def run(job):
        test, p, temp, mt, t, key = job
        return key, call_once(p, temp, mt)

    start = time.monotonic(); done = 0
    workers = int(os.environ.get("Z_WORKERS", "6"))
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = {ex.submit(run, j): j for j in todo}
        for fut in as_completed(futs):
            key, res = fut.result()
            progress[key] = res; done += 1
            if done % 30 == 0:
                json.dump(progress, open(PROGRESS, "w"))
                print(f"  +{done} ({len(progress)}/{total})", flush=True)
            if time.monotonic() - start > BUDGET:
                for f in futs:
                    if not f.done():
                        f.cancel()
                break
    json.dump(progress, open(PROGRESS, "w"))
    remaining = total - len(progress)
    if remaining <= 0:
        print(f"ALL DONE: {len(progress)}/{total}")
        finalize(progress)
    else:
        print(f"PARTIAL: {len(progress)}/{total} (+{done} this run, {remaining} left). Re-run.")


def reval(r):
    """Re-derive the numeric value from the preserved raw text using the current
    (robust) parser, so a parser fix retroactively corrects stored rows without
    any new API calls. Records an audit note when the re-parse changes the value."""
    if not r.get("ok"):
        return None
    v = extract_number(r["raw"])
    old = r.get("value")
    r["value"] = v
    if old is not None and v is not None and abs(old - v) > 1e-9 * (abs(v) + 1):
        r["parse_note"] = f"reparsed {old!r}->{v!r} from raw {r['raw']!r}"
    return v


def finalize(progress):
    import csv
    for r in progress.values():
        reval(r)
    json.dump(progress, open(PROGRESS, "w"))
    # ---- DIGITS ----
    drows = [(f"DIGITS#{t}", progress[f"DIGITS#{t}"]) for t in range(100)]
    with open(os.path.join(HERE, "Z_DIGITS_COLD_T0.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["trial", "raw", "value", "true", "abs_err", "correct"])
        for k, r in drows:
            v = r["value"]
            correct = (v is not None and int(v) == DIGIT_TRUE)
            ae = "" if v is None else abs(v - DIGIT_TRUE)
            w.writerow([k.split("#")[1], r["raw"], v, DIGIT_TRUE, ae, correct])
    # ---- ZETA ----
    with open(os.path.join(HERE, "Z_ZETA_COLD_T0.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["trial", "raw", "value", "true_abs", "rel_err"])
        for t in range(20):
            r = progress[f"ZETA#{t}"]; v = r["value"]
            re_ = "" if v is None else abs(v - ZETA_TRUE_ABS) / ZETA_TRUE_ABS
            w.writerow([t, r["raw"], v, ZETA_TRUE_ABS, re_])
    # ---- BESSEL SWEEP ----
    sweep = []
    with open(os.path.join(HERE, "Z_BESSEL_TSWEEP.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["temperature", "trial", "raw", "value", "true", "rel_err"])
        for temp in [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]:
            errs = []
            for t in range(20):
                r = progress[f"BESSEL_T{temp}#{t}"]; v = r["value"]
                re_ = None if v is None else abs(v - BESSEL_TRUE) / BESSEL_TRUE
                if re_ is not None:
                    errs.append(re_)
                w.writerow([temp, t, r["raw"], v, BESSEL_TRUE,
                            "" if re_ is None else re_])
            sweep.append((temp, errs))
    # ---- summary JSON ----
    def stats(errs):
        if not errs:
            return {"n": 0}
        m = sum(errs) / len(errs)
        return {"n": len(errs), "mean_rel_err": m,
                "min": min(errs), "max": max(errs)}
    digit_vals = [progress[f"DIGITS#{t}"]["value"] for t in range(100)]
    digit_ok = [v for v in digit_vals if v is not None]
    n_correct = sum(1 for v in digit_ok if int(v) == DIGIT_TRUE)
    zeta_vals = [progress[f"ZETA#{t}"]["value"] for t in range(20)]
    zeta_ok = [v for v in zeta_vals if v is not None]
    zeta_errs = [abs(v - ZETA_TRUE_ABS) / ZETA_TRUE_ABS for v in zeta_ok]
    summary = {
        "model": MODEL,
        "digits": {"n": 100, "true": DIGIT_TRUE,
                   "distinct": {str(k): digit_vals.count(k) for k in set(digit_vals)},
                   "n_correct": n_correct,
                   "error_rate": (len(digit_ok) - n_correct) / len(digit_ok) if digit_ok else None},
        "zeta": {"true_complex": str(ZETA_C), "true_abs": ZETA_TRUE_ABS,
                 "distinct": {str(k): zeta_vals.count(k) for k in set(zeta_vals)},
                 **stats(zeta_errs)},
        "bessel_true": BESSEL_TRUE,
        "bessel_sweep": {str(temp): stats(errs) for temp, errs in sweep},
    }
    json.dump(summary, open(os.path.join(HERE, "Z_PROTOCOL_FULL_summary.json"), "w"), indent=2)
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
