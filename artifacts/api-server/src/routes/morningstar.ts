import { Router, type IRouter } from "express";
import { existsSync, readFileSync, statSync } from "node:fs";
import { createHash } from "node:crypto";
import path from "node:path";

const router: IRouter = Router();

// Mirrors scripts/check-genesis-seal.py: SHA-256 of the immutable preamble
// (header comment lines + the five Genesis lines, through and including the
// "--- GENESIS SEAL ---" marker, each terminated by '\n').
const EXPECTED_SEAL_SHA =
  "eecbcd9a540aa7a2c90edd23827c73e4d1bb5af641d352f70a5de849b21f875f";
const SEAL_MARKER = "--- GENESIS SEAL ---";
const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 500;
const COMMENT_PREFIX = "#";

function resolveRepoRoot(): string {
  const candidates = [
    process.cwd(),
    path.resolve(process.cwd(), "..", ".."),
    path.resolve(process.cwd(), ".."),
  ];
  for (const c of candidates) {
    if (existsSync(path.join(c, "data", "hits.txt"))) return c;
  }
  return candidates[0];
}

const REPO_ROOT = resolveRepoRoot();
const HITS_PATH = path.join(REPO_ROOT, "data", "hits.txt");

interface ParsedProbe {
  lineNumber: number;
  raw: string;
  ts: string | null;
  timestamp: string | null;
  h: number | null;
  n: number | null;
  re: number | null;
  im: number | null;
  lNonvanish: boolean | null;
  rhOk: boolean | null;
  kmsBeta: number | null;
  tag: string | null;
  lAbs: string | null;
  reason: string | null;
  sha: string | null;
}

const KNOWN_TAGS = new Set([
  "MPMATH_ZETA",
  "MPMATH_DIRICHLET_TRIVIAL",
  "NEEDS_SAGE",
]);

function parseBool(v: string | undefined): boolean | null {
  if (v === undefined) return null;
  if (v === "True") return true;
  if (v === "False") return false;
  return null;
}

function parseInteger(v: string | undefined): number | null {
  if (v === undefined) return null;
  const n = Number.parseInt(v, 10);
  return Number.isFinite(n) ? n : null;
}

function parseFloatOrNull(v: string | undefined): number | null {
  if (v === undefined) return null;
  const n = Number.parseFloat(v);
  return Number.isFinite(n) ? n : null;
}

function nanosToIso(ts: string | null): string | null {
  if (!ts) return null;
  // ts is nanoseconds since the Unix epoch as recorded by the kernel; we
  // convert via BigInt to avoid float precision loss, then format as ISO-8601.
  try {
    const big = BigInt(ts);
    const ms = Number(big / 1_000_000n);
    const d = new Date(ms);
    if (Number.isNaN(d.getTime())) return null;
    return d.toISOString();
  } catch {
    return null;
  }
}

function parseProbeLine(raw: string, lineNumber: number): ParsedProbe {
  // Format: probe ts=... h=... N=... re=... im=... L_nonvanish=... RH_ok=...
  //         <TAG> [L_abs=...] [reason=...] sha=...
  const fields: Record<string, string> = {};
  let tag: string | null = null;
  const tokens = raw.split(/\s+/);
  for (const tok of tokens) {
    if (!tok || tok === "probe") continue;
    const eq = tok.indexOf("=");
    if (eq === -1) {
      if (KNOWN_TAGS.has(tok) && tag === null) tag = tok;
      continue;
    }
    const key = tok.slice(0, eq);
    const val = tok.slice(eq + 1);
    fields[key] = val;
  }
  const ts = fields["ts"] ?? null;
  return {
    lineNumber,
    raw,
    ts,
    timestamp: nanosToIso(ts),
    h: parseInteger(fields["h"]),
    n: parseInteger(fields["N"]),
    re: parseFloatOrNull(fields["re"]),
    im: parseFloatOrNull(fields["im"]),
    lNonvanish: parseBool(fields["L_nonvanish"]),
    rhOk: parseBool(fields["RH_ok"]),
    kmsBeta: parseFloatOrNull(fields["kms_beta"]),
    tag,
    lAbs: fields["L_abs"] ?? null,
    reason: fields["reason"] ?? null,
    sha: fields["sha"] ?? null,
  };
}

router.get("/morningstar/hits", (req, res) => {
  let limit = DEFAULT_LIMIT;
  const rawLimit = req.query["limit"];
  if (typeof rawLimit === "string" && rawLimit.length > 0) {
    const parsed = Number.parseInt(rawLimit, 10);
    if (!Number.isFinite(parsed) || parsed < 1) {
      res.status(400).json({ error: "`limit` must be a positive integer." });
      return;
    }
    limit = Math.min(parsed, MAX_LIMIT);
  }

  let content: string;
  let lastModified: string;
  try {
    content = readFileSync(HITS_PATH, "utf8");
    lastModified = statSync(HITS_PATH).mtime.toISOString();
  } catch (err) {
    req.log.error(
      { err, path: HITS_PATH },
      "Failed to read MorningStar-Lab ledger",
    );
    res.status(500).json({ error: "MorningStar-Lab ledger unavailable." });
    return;
  }

  const lines = content.split("\n");
  const markerIdx = lines.indexOf(SEAL_MARKER);
  if (markerIdx === -1) {
    req.log.error({ path: HITS_PATH }, "Ledger missing Genesis seal marker");
    res.status(500).json({
      error: `MorningStar-Lab ledger missing required marker ${SEAL_MARKER}.`,
    });
    return;
  }

  const preambleLines = lines.slice(0, markerIdx + 1);
  const headerLines: string[] = [];
  const genesisLines: string[] = [];
  for (const line of preambleLines) {
    if (line.startsWith(COMMENT_PREFIX) && genesisLines.length === 0) {
      headerLines.push(line);
    } else {
      genesisLines.push(line);
    }
  }

  // Compute seal exactly the same way scripts/check-genesis-seal.py does:
  // "\n".join(lines[: marker_idx + 1]) + "\n"
  const preambleBytes = Buffer.from(preambleLines.join("\n") + "\n", "utf8");
  const sealSha = createHash("sha256").update(preambleBytes).digest("hex");
  const sealOk = sealSha === EXPECTED_SEAL_SHA;

  // Everything after the marker, dropping the trailing empty element that
  // comes from a file ending in '\n', is a probe entry.
  const probeStart = markerIdx + 1;
  const probeLinesAll: { raw: string; lineNumber: number }[] = [];
  for (let i = probeStart; i < lines.length; i++) {
    const raw = lines[i];
    if (raw.length === 0) continue;
    probeLinesAll.push({ raw, lineNumber: i + 1 });
  }

  // Most-recent-first slice, capped at `limit`.
  const sliced = probeLinesAll.slice(-limit).reverse();
  const probes = sliced.map((p) => parseProbeLine(p.raw, p.lineNumber));

  res.json({
    headerLines,
    genesisLines,
    sealSha,
    expectedSealSha: EXPECTED_SEAL_SHA,
    sealOk,
    probes,
    totalProbes: probeLinesAll.length,
    returnedProbes: probes.length,
    limit,
    ledgerPath: HITS_PATH,
    lastModified,
  });
});

export default router;
