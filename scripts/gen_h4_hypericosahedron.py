#!/usr/bin/env python3
"""Deterministic generator for the H4 / 600-cell (hypericosahedron) visuals.

Two outputs, in the same honest style as the Wall256 docs set:

  docs/H4_Hypericosahedron.png  -- the genuine 600-cell projected on the H4
      Coxeter plane (the iconic 30-fold image). The 120 vertices ARE the H4
      root system, generated deterministically by reflection-closure; the
      Coxeter plane is the (Re, Im) span of the Coxeter element's principal
      eigenvector (eigenvalue e^{i*pi/15}). NO AI, NO hand-placed points.

  docs/H4_CoxeterModel.svg      -- "what is actually machine-checked": the H4
      Coxeter diagram o--o--o--(5)--o (weights 1,1,phi), the 4x4 matrix
      B = 2I - M_H4, the phi-refutation (phi is NOT an eigenvalue), and the
      OPEN hypotheses + R-model.

HONESTY (matches Towers/YM/Wall261_H4Defect, Wall262_ConnectiveRatio,
Wall262a_RatioModel, Wall263_CoxeterSpectral):
  - The 600-/120-cell POLYTOPE is NOT formalized in Lean. The projection is
    REAL but ILLUSTRATIVE geometry of the H4 symmetry.
  - Machine-checked: phi^2 = phi+1; C = 1+phi = phi^2; the 4x4 Coxeter
    characteristic polynomial; the refutation phi_not_root (phi is NOT a root)
    => "lambda_max(2I - M_H4) = phi" is FALSE.
  - Documentary only: the true spectral radius 2*cos(pi/30) ~= 1.989 (h=30).
  - OPEN: h_spec, h_kp, h_defect, h_rate, h_graph. YM Status: Open. No mass gap.
"""
import html
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

OUT = "docs"
os.makedirs(OUT, exist_ok=True)
PHI = (1 + 5 ** 0.5) / 2

# ----------------------------------------------------------- palette / fonts
INK, INK2, MUTED = "#1a1d27", "#3a4051", "#6b7280"
PAPER, PANEL, BORDER = "#ffffff", "#f5f6fa", "#d4d8e2"
GREEN, OPENRED, AMBER, BLUE = "#1f9d57", "#d23f3f", "#c97a00", "#23408e"
SANS = "DejaVu Sans, Arial, Helvetica, sans-serif"
MONO = "DejaVu Sans Mono, Menlo, Consolas, monospace"
FDIR = "/usr/share/fonts/truetype/dejavu"

FOOTER1 = ("Faithful to  Wall261_H4Defect \u00b7 Wall262_ConnectiveRatio \u00b7 "
           "Wall262a_RatioModel \u00b7 Wall263_CoxeterSpectral")
FOOTER2 = ("AXIOMS = {propext, Classical.choice, Quot.sound}     \u00b7     "
           "YM_STATUS = OPEN")


# ================================================================ H4 geometry
def h4_roots_and_plane():
    def cc(m):
        return -math.cos(math.pi / m)
    G = np.array([[1, cc(3), 0, 0],
                  [cc(3), 1, cc(3), 0],
                  [0, cc(3), 1, cc(5)],
                  [0, 0, cc(5), 1]], dtype=float)
    L = np.linalg.cholesky(G)              # rows = unit simple roots in R^4
    simple = [L[i] / np.linalg.norm(L[i]) for i in range(4)]

    def refl(x, a):
        return x - 2 * np.dot(x, a) * a

    roots = [s.copy() for s in simple]

    def known(v):
        return any(np.allclose(v, s, atol=1e-7) for s in roots)

    changed = True
    while changed:
        changed = False
        for v in list(roots):
            for a in simple:
                w = refl(v, a)
                if not known(w):
                    roots.append(w)
                    changed = True
    R = np.array(roots)
    assert len(R) == 120, f"expected 120 roots, got {len(R)}"

    # Coxeter element c = s1 s2 s3 s4 and its principal eigenplane
    def reflmat(a):
        return np.eye(4) - 2 * np.outer(a, a)
    C = np.eye(4)
    for a in simple:
        C = C @ reflmat(a)
    vals, vecs = np.linalg.eig(C)
    idx = int(np.argmin([abs(np.angle(v) - math.pi / 15) for v in vals]))
    ev = vecs[:, idx]
    u = np.real(ev); u /= np.linalg.norm(u)
    w = np.imag(ev); w = w - np.dot(w, u) * u; w /= np.linalg.norm(w)

    P = np.array([[np.dot(r, u), np.dot(r, w)] for r in R])
    # edges: adjacent 600-cell vertices have inner product phi/2 (= cos 36)
    edges = []
    td = PHI / 2
    for i in range(len(R)):
        for j in range(i + 1, len(R)):
            if abs(np.dot(R[i], R[j]) - td) < 1e-6:
                edges.append((i, j))
    return P, edges


# ----------------------------------------------------------- color utilities
def hx(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))

def lerp(a, b, t):
    return tuple(int(round(a[k] + (b[k] - a[k]) * t)) for k in range(3))

def ring_color(t):
    """t in [0,1] -> indigo -> blue -> teal -> gold."""
    stops = [(0.00, hx("#2a2a6a")), (0.40, hx("#2f6fd0")),
             (0.72, hx("#13a39b")), (1.00, hx("#d99a16"))]
    for k in range(len(stops) - 1):
        t0, c0 = stops[k]; t1, c1 = stops[k + 1]
        if t <= t1:
            return lerp(c0, c1, (t - t0) / (t1 - t0) if t1 > t0 else 0)
    return stops[-1][1]


# ================================================================ PNG figure
def build_png():
    P, edges = h4_roots_and_plane()
    rad = np.linalg.norm(P, axis=1)
    rmax = rad.max()
    tnorm = rad / rmax

    S = 2
    W, H = 1120, 1250
    img = Image.new("RGB", (W * S, H * S), hx(PAPER))
    d = ImageDraw.Draw(img)

    def F(name, size):
        return ImageFont.truetype(os.path.join(FDIR, name), size * S)
    f_h1 = F("DejaVuSans-Bold.ttf", 27)
    f_sub = F("DejaVuSans.ttf", 14)
    f_lab = F("DejaVuSans-Bold.ttf", 15)
    f_body = F("DejaVuSans.ttf", 13.5)
    f_mono = F("DejaVuSansMono.ttf", 13)
    f_small = F("DejaVuSans.ttf", 12.5)

    def T(x, y, s, fnt, fill, anchor=None):
        d.text((x * S, y * S), s, font=fnt, fill=hx(fill), anchor=anchor)

    T(40, 26, "The hypericosahedron \u2014 600-cell on the H4 Coxeter plane",
      f_h1, INK)
    T(40, 64, "120 vertices = the H4 root system  \u00b7  720 edges  \u00b7  "
              "30-fold symmetry (Coxeter number h = 30)  \u00b7  deterministic "
              "projection, no AI", f_sub, MUTED)

    # projection placement
    cx, cy = W / 2, 120 + 880 / 2
    span = 880
    scale = (span / 2 - 30) / rmax

    def XY(p):
        return (cx + p[0] * scale, cy - p[1] * scale)

    # edges on an RGBA layer for soft additive overlap
    ov = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    od = ImageDraw.Draw(ov)
    for (i, j) in edges:
        x1, y1 = XY(P[i]); x2, y2 = XY(P[j])
        tm = (tnorm[i] + tnorm[j]) / 2
        col = ring_color(tm) + (150,)
        od.line([x1 * S, y1 * S, x2 * S, y2 * S], fill=col, width=max(1, int(1.6 * S)))
    img = Image.alpha_composite(img.convert("RGBA"), ov).convert("RGB")
    d = ImageDraw.Draw(img)

    # vertices
    for k in range(len(P)):
        x, y = XY(P[k])
        col = ring_color(tnorm[k])
        r = 5
        d.ellipse([(x - r) * S, (y - r) * S, (x + r) * S, (y + r) * S],
                  fill=col, outline=hx("#ffffff"), width=max(1, int(0.6 * S)))

    # re-acquire fonts after image rebuild
    d = ImageDraw.Draw(img)

    # honesty box
    ly = H - 192
    d.rounded_rectangle([40 * S, ly * S, (W - 40) * S, (H - 62) * S],
                        radius=12 * S, fill=hx("#fbf3e6"), outline=hx("#e7d5ac"),
                        width=S)
    T(60, ly + 14, "Illustrative geometry \u2014 honest scope", f_lab, AMBER)
    T(60, ly + 38,
      "This is the real 600-cell ({3,3,5}); its symmetry group is H4. The "
      "POLYTOPE is NOT formalized in Lean.", f_body, INK2)
    T(60, ly + 58,
      "Machine-checked = the concrete matrix B, det_charmatrix (det(\u03bbI\u2212B) "
      "= coxeterCharpoly), and", f_body, INK2)
    T(60, ly + 78,
      "phi_not_mem_spectrum (\u03c6 \u2209 spectrum \u211d B) \u2014 so "
      "\u201c\u03bb_max = \u03c6\u201d is FALSE, machine-checked, not just hand-"
      "computed.", f_body, INK2)
    T(60, ly + 98,
      "DOCUMENTARY: only the IDENTITY of the largest eigenvalue "
      "2\u00b7cos(\u03c0/30) \u2248 1.989 (h=30).  LATTICE scope, NOT the Clay "
      "mass gap.  YM: Open.", f_body, INK2)
    T(40, H - 42, FOOTER1, f_small, MUTED)
    T(40, H - 22, FOOTER2, f_small, MUTED)

    img = img.resize((W, H), Image.LANCZOS)
    img.save(os.path.join(OUT, "H4_Hypericosahedron.png"))
    print("wrote H4_Hypericosahedron.png", f"({W}x{H}); edges={len(edges)}")


# ================================================================ SVG card
def esc(s):
    return html.escape(str(s), quote=True)

def rr(x, y, w, h, r, fill, stroke=None, sw=1.5):
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" ry="{r}" fill="{fill}"'
    if stroke:
        s += f' stroke="{stroke}" stroke-width="{sw}"'
    return s + '/>'

def tx(x, y, s, size, fill=INK, family=SANS, weight="normal", style="normal",
       anchor="start"):
    return (f'<text x="{x}" y="{y}" font-family="{family}" font-size="{size}" '
            f'font-weight="{weight}" font-style="{style}" fill="{fill}" '
            f'text-anchor="{anchor}">{esc(s)}</text>')

def pill(xr, y, label, color, h=22):
    w = 14 + int(len(label) * 8.6)
    x = xr - w
    return (rr(x, y, w, h, h / 2, color)
            + tx(x + w / 2, y + h - 6.5, label, 12.5, "#ffffff", SANS, "bold",
                 anchor="middle"))

def build_svg():
    W = 1060
    parts = []
    y = 54
    parts.append(tx(40, y, "H4 / 600-cell \u2014 what is machine-checked", 25,
                    INK, SANS, "bold")); y += 26
    parts.append(tx(40, y, "the formalized core behind the connective-ratio "
                           "scaffold  \u00b7  PROVEN \u00b7 DOCUMENTARY \u00b7 "
                           "NOT FORMALIZED \u00b7 OPEN", 14, MUTED)); y += 30

    # --- Coxeter diagram ---
    parts.append(rr(40, y, W - 80, 110, 12, PANEL, BORDER))
    parts.append(tx(60, y + 26, "H4 Coxeter diagram", 14.5, INK, SANS, "bold"))
    nodes_x = [180, 360, 540, 720]
    ny = y + 70
    labels = ["3", "3", "5"]
    weights = ["1", "1", "\u03c6"]
    for k in range(3):
        x1, x2 = nodes_x[k], nodes_x[k + 1]
        parts.append(f'<line x1="{x1}" y1="{ny}" x2="{x2}" y2="{ny}" '
                     f'stroke="{INK2}" stroke-width="2.5"/>')
        midx = (x1 + x2) / 2
        parts.append(tx(midx, ny - 12, labels[k], 14, BLUE, MONO, "bold",
                        anchor="middle"))
        parts.append(tx(midx, ny + 26, "w=" + weights[k], 12.5, MUTED, MONO,
                        anchor="middle"))
    for nx in nodes_x:
        parts.append(f'<circle cx="{nx}" cy="{ny}" r="9" fill="{PAPER}" '
                     f'stroke="{INK}" stroke-width="2.5"/>')
    parts.append(tx(W - 60, y + 26, "edge weights 1, 1, \u03c6   "
                    "(\u03c6 = 2\u00b7cos(\u03c0/5))", 12.5, MUTED, MONO,
                    anchor="end"))
    y += 110 + 18

    # --- matrix B + true radius ---
    bh = 150
    half = (W - 80 - 20) / 2
    # matrix box (PROVEN: B, det, and phi-not-eigenvalue now machine-checked)
    parts.append(rr(40, y, half, bh, 12, PANEL, BORDER))
    parts.append(rr(40, y, 6, bh, 3, GREEN))
    parts.append(pill(40 + half - 14, y + 12, "PROVEN", GREEN))
    parts.append(tx(60, y + 28, "B = 2I \u2212 M_H4", 14.5, INK, SANS, "bold"))
    Bm = [["0", "1", "0", "0"],
          ["1", "0", "1", "0"],
          ["0", "1", "0", "\u03c6"],
          ["0", "0", "\u03c6", "0"]]
    gx, gy, cell = 70, y + 44, 26
    for r in range(4):
        for c in range(4):
            col = BLUE if Bm[r][c] != "0" else MUTED
            parts.append(tx(gx + c * cell + cell / 2, gy + r * cell + 18,
                            Bm[r][c], 16, col, MONO, "bold", anchor="middle"))
    # bracket lines
    bx0, bx1 = gx - 6, gx + 4 * cell + 6
    by0, by1 = gy + 2, gy + 4 * cell + 2
    for xx, d1 in [(bx0, 8), (bx1, -8)]:
        parts.append(f'<path d="M{xx + d1},{by0} L{xx},{by0} L{xx},{by1} '
                     f'L{xx + d1},{by1}" fill="none" stroke="{INK}" '
                     f'stroke-width="1.6"/>')
    nx = gx + 4 * cell + 34
    parts.append(tx(nx, gy + 2 * cell - 8, "label-5 edge \u21a6 \u03c6", 12.5,
                    MUTED, SANS))
    parts.append(tx(nx, gy + 2 * cell + 12, "det_charmatrix: det(\u03bbI\u2212B)",
                    11.5, MUTED, SANS))
    parts.append(tx(nx, gy + 2 * cell + 28, "= coxeterCharpoly (in Lean)",
                    11.5, MUTED, SANS))

    # true radius box
    rx0 = 40 + half + 20
    parts.append(rr(rx0, y, half, bh, 12, PANEL, BORDER))
    parts.append(rr(rx0, y, 6, bh, 3, GREEN))
    parts.append(pill(rx0 + half - 14, y + 12, "PROVEN", GREEN))
    parts.append(tx(rx0 + 18, y + 28, "Spectral reading", 14.5, GREEN,
                    SANS, "bold"))
    parts.append(tx(rx0 + 18, y + 52,
                    "\u03c6 is not a root \u21d2 \u03c6 is NOT an eigenvalue,",
                    12.8, INK, SANS))
    parts.append(tx(rx0 + 18, y + 72,
                    "so  \u201c\u03bb_max(2I \u2212 M_H4) = \u03c6\u201d  is "
                    "FALSE.", 12.8, INK, SANS))
    parts.append(tx(rx0 + 18, y + 98,
                    "phi_not_mem_spectrum :  \u03c6 \u2209 spectrum \u211d B",
                    12.5, INK, MONO, "bold"))
    parts.append(tx(rx0 + 18, y + 120,
                    "True Perron value 2\u00b7cos(\u03c0/30) \u2248 1.989 (h=30)",
                    12, INK2, SANS))
    parts.append(tx(rx0 + 18, y + 138,
                    "stays documentary (full spectrum not formalized).",
                    12, INK2, SANS))
    y += bh + 18

    # --- PROVEN panel ---
    ph = 182
    parts.append(rr(40, y, W - 80, ph, 12, PANEL, BORDER))
    parts.append(rr(40, y, 6, ph, 3, GREEN))
    parts.append(pill(W - 40 - 14, y + 12, "PROVEN", GREEN))
    parts.append(tx(60, y + 28, "Machine-checked (classical trio, no sorry)",
                    14.5, GREEN, SANS, "bold"))
    proven = [
        "phi_sq_eq :  \u03c6\u00b2 = \u03c6 + 1        \u2234  C = 1 + \u03c6 = "
        "\u03c6\u00b2 \u2248 2.618",
        "coxeterCharpoly \u03c6 = \u2212(\u03c6\u00b2)        (H4 charpoly "
        "evaluated at \u03c6)",
        "phi_not_root :  coxeterCharpoly \u03c6 \u2260 0",
        "det_charmatrix :  det(\u03bb\u00b7I \u2212 B) = coxeterCharpoly \u03bb   "
        "(Laplace cofactor expansion)",
        "phi_not_mem_spectrum :  \u03c6 \u2209 spectrum \u211d B   (\u03c6 is NOT "
        "an eigenvalue)",
    ]
    yy = y + 52
    for ln in proven:
        parts.append(tx(64, yy, ln, 13.5, INK, MONO)); yy += 21
    parts.append(tx(64, yy + 1,
                    "\u21b3 B is a concrete Matrix (Fin 4) (Fin 4) \u211d; the "
                    "det\u2194charpoly bridge and \u201c\u03c6 not an eigenvalue\u201d "
                    "are now in Lean.", 13, INK2, SANS, "italic"))
    y += ph + 18

    # --- NOT FORMALIZED + OPEN row ---
    nh = 150
    half2 = (W - 80 - 20) / 2
    parts.append(rr(40, y, half2, nh, 12, "#fdeaea", "#eab8b8"))
    parts.append(pill(40 + half2 - 14, y + 12, "NOT FORMALIZED", OPENRED))
    parts.append(tx(60, y + 30, "Not constructed in Lean", 14.5, OPENRED,
                    SANS, "bold"))
    nf = ["the 600-cell / 120-cell POLYTOPE",
          "(its 120 / 600 vertices and edges)",
          "the H4 adjacency-graph spectrum",
          "the SU(2) polymer-rate win \u2014 Status: Open"]
    yy = y + 58
    for ln in nf:
        parts.append(tx(60, yy, "\u2022 " + ln, 13, INK2, SANS)); yy += 21

    ox0 = 40 + half2 + 20
    parts.append(rr(ox0, y, half2, nh, 12, PANEL, BORDER))
    parts.append(pill(ox0 + half2 - 14, y + 12, "OPEN", "#7a59c2"))
    parts.append(tx(ox0 + 18, y + 30, "Named-open hypotheses", 14.5, "#5b3fa0",
                    SANS, "bold"))
    op = ["h_spec :  EffDeg(x) \u2264 \u03c6",
          "h_kp :  weighted Koteck\u00fd\u2013Preiss combinator",
          "h_defect :  Defect \u2264 log(1 + \u03c6\u00b7R)",
          "h_rate :  log 7 + 22/25 \u2264 I_E",
          "h_graph :  Defect \u2264 log(1+\u03c6) \u2212 \u03b5"]
    yy = y + 56
    for ln in op:
        parts.append(tx(ox0 + 18, yy, ln, 12.5, INK2, MONO)); yy += 19
    y += nh + 18

    # --- R-model strip ---
    parts.append(rr(40, y, W - 80, 40, 8, INK, None))
    parts.append(tx(58, y + 25,
                    "Wall262a R-model (invented weights):  R(a) = 1 \u2212 "
                    "(a/2 + a\u00b2/3 + a\u00b3/16 + a\u2074/60)   \u00b7   "
                    "R(e^(\u22120.88)) \u2264 1743/2000 = 0.8715", 13.5,
                    "#e7ebf5", MONO))
    y += 40 + 16

    parts.append(tx(40, y + 12, FOOTER1, 11.5, MUTED, MONO))
    parts.append(tx(40, y + 30, FOOTER2, 11.5, MUTED, MONO))
    Ht = int(y + 46)

    out = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{Ht}" '
           f'viewBox="0 0 {W} {Ht}" font-family="{SANS}">'
           f'<rect width="{W}" height="{Ht}" fill="{PAPER}"/>'
           + "".join(parts) + "</svg>")
    with open(os.path.join(OUT, "H4_CoxeterModel.svg"), "w", encoding="utf-8") as f:
        f.write(out)
    print("wrote H4_CoxeterModel.svg", f"({W}x{Ht})")


if __name__ == "__main__":
    build_png()
    build_svg()
    print("done")
