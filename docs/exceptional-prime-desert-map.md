# Exceptional-Prime Desert Map — α₀ = 299 + π/10

**Status: data report, pending independent verification. No new mathematics is claimed or proved. GRH/RH stay OPEN.**

**Rule.** A prime `p` is *exceptional* ⟺ `‖p·π/10‖ < 1/p`, where `‖x‖` = distance to nearest integer. Since `299·p ∈ ℤ`, this equals `‖p·(299+π/10)‖`, so the α₀ test and the π/10 test are identical.

**Method.** Exact CF convergents + upper-semiconvergents of π/10; integer exceptional test against **8,300-digit** π with a decision certificate (min margin ~10⁸²⁹⁵ ≫ 10⁸⁰⁰⁰ over `p ≤ 10⁴⁰⁰⁰`). Primality: BPSW (no known counterexample, but **not** a formal certificate for the 1000+ digit entries). `r = p·‖p·π/10‖`; the test passes ⟺ `r < 1`. *Test index* = number of integers tested from 1 to p = p itself.

**Result: exactly 20 exceptional primes to 10⁴⁰⁰⁰.** C_unwt(total) = 1.4336768 (< 2√13 = 7.2111). Exact integers + all fields: `data/desert_map.csv`.

## P5 explicit verification (the centerpiece)
```
P5            = 3993746143633   (13 digits)
‖P5·π/10‖     = 3.81503838596e-14
1/P5          = 2.50391478085e-13
‖P5·π/10‖ < 1/P5 ?  True   (r = P5·‖P5·π/10‖ = 0.1523629484 < 1)
```

## The 20 exceptional primes

### PRIME #1 — 1 digit  ·  [Trio]
- Exact: `2`
- Test index (integers 1..p): p itself (1-digit)
- r = p·‖p·π/10‖ = 0.74336294  (< 1 ✓)
- ‖p·π/10‖ = 0.3716815
- BPSW prime: True
- Gap from previous: — (first)
- C_unwt cumulative: 0.6931472
- C_wt cumulative: 1.3862944

### PRIME #2 — 1 digit  ·  [Trio]
- Exact: `3`
- Test index (integers 1..p): p itself (1-digit)
- r = p·‖p·π/10‖ = 0.17256661  (< 1 ✓)
- ‖p·π/10‖ = 0.0575222
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 1
- Tests since previous: 1
- Desert width: 0 consecutive non-exceptional integers
- C_unwt cumulative: 1.242453
- C_wt cumulative: 3.0342128

### PRIME #3 — 2 digits  ·  [Trio]
- Exact: `19`
- Test index (integers 1..p): p itself (2-digit)
- r = p·‖p·π/10‖ = 0.58850521  (< 1 ✓)
- ‖p·π/10‖ = 0.03097396
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 16
- Tests since previous: 16
- Desert width: 15 consecutive non-exceptional integers
- C_unwt cumulative: 1.406033
- C_wt cumulative: 6.1422317

### PRIME #4 — 3 digits  ·  [Trio_End]
- Exact: `191`
- Test index (integers 1..p): p itself (3-digit)
- r = p·‖p·π/10‖ = 0.84415956  (< 1 ✓)
- ‖p·π/10‖ = 0.004419684
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 172
- Tests since previous: 172
- Desert width: 171 consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 11.422149

--- DESERT 1 START (after the trio) ---

### PRIME #5 — 13 digits  ·  [GIANT]
- Exact: `3993746143633`
- Test index (integers 1..p): p itself (13-digit)
- r = p·‖p·π/10‖ = 0.15236295  (< 1 ✓)
- ‖p·π/10‖ = 3.815038e-14
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 3993746143442
- Tests since previous: 3993746143442
- Desert width: 3993746143441 consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 40.437899

--- DESERT 1 END · DESERT 2 START ---

### PRIME #6 — 16 digits  ·  [GIANT]
- Exact: `3224057731518397`
- Test index (integers 1..p): p itself (16-digit)
- r = p·‖p·π/10‖ = 0.77495077  (< 1 ✓)
- ‖p·π/10‖ = 2.40365e-16
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 3220063985374764
- Tests since previous: 3220063985374764
- Desert width: 3220063985374763 consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 76.147317

--- DESERT 2 END · DESERT 3 START ---

### PRIME #7 — 24 digits  ·  [GIANT]
- Exact: `631474305334326148720631`
- Test index (integers 1..p): p itself (24-digit)
- r = p·‖p·π/10‖ = 0.14419989  (< 1 ✓)
- ‖p·π/10‖ = 2.283543e-25
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 631474302110268417202234
- Tests since previous: 631474302110268417202234
- Desert width: 631474302110268417202233 consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 130.94966

--- DESERT 3 END · DESERT 4 START ---

### PRIME #8 — 35 digits  ·  [GIANT]
- Exact: `10531012662744699702276055940873441`
- Test index (integers 1..p): p itself (35-digit)
- r = p·‖p·π/10‖ = 0.35705493  (< 1 ✓)
- ‖p·π/10‖ = 3.390509e-35
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 10531012662113225396941729792152810
- Tests since previous: 10531012662113225396941729792152810
- Desert width: 10531012662113225396941729792152809 consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 209.28929

--- DESERT 4 END · DESERT 5 START ---

### PRIME #9 — 76 digits  ·  [GIANT]
- Exact (76 digits): see `data/desert_map.csv`  (`763655502743292386…274704893143`)
- Test index (integers 1..p): p itself (76-digit)
- r = p·‖p·π/10‖ = 0.43667326  (< 1 ✓)
- ‖p·π/10‖ = 5.718197e-77
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 763655502743292386…218764019702  (76 digits)
- Tests since previous: 763655502743292386…218764019702  (76 digits)
- Desert width: 763655502743292386…218764019701  (76 digits) consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 384.01612

--- DESERT 5 END · DESERT 6 START ---

### PRIME #10 — 95 digits  ·  [GIANT]
- Exact (95 digits): see `data/desert_map.csv`  (`878228977826120898…462065410669`)
- Test index (integers 1..p): p itself (95-digit)
- r = p·‖p·π/10‖ = 0.8334696  (< 1 ✓)
- ‖p·π/10‖ = 9.490345e-96
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 878228977826120898…187360517526  (95 digits)
- Tests since previous: 878228977826120898…187360517526  (95 digits)
- Desert width: 878228977826120898…187360517525  (95 digits) consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 602.63186

--- DESERT 6 END · DESERT 7 START ---

### PRIME #11 — 111 digits  ·  [GIANT]
- Exact (111 digits): see `data/desert_map.csv`  (`489830773366832287…692784889819`)
- Test index (integers 1..p): p itself (111-digit)
- r = p·‖p·π/10‖ = 0.54052883  (< 1 ✓)
- ‖p·π/10‖ = 1.103501e-111
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 489830773366832200…230719479150  (111 digits)
- Tests since previous: 489830773366832200…230719479150  (111 digits)
- Desert width: 489830773366832200…230719479149  (111 digits) consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 857.50511

--- DESERT 7 END · DESERT 8 START ---

### PRIME #12 — 372 digits  ·  [GIANT]
- Exact (372 digits): see `data/desert_map.csv`  (`194626099310997110…516236611721`)
- Test index (integers 1..p): p itself (372-digit)
- r = p·‖p·π/10‖ = 0.52481118  (< 1 ✓)
- ‖p·π/10‖ = 2.69651e-372
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 194626099310997110…823451721902  (372 digits)
- Tests since previous: 194626099310997110…823451721902  (372 digits)
- Desert width: 194626099310997110…823451721901  (372 digits) consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 1712.4301

--- DESERT 8 END · DESERT 9 START ---

### PRIME #13 — 859 digits  ·  [GIANT]
- Exact (859 digits): see `data/desert_map.csv`  (`883216099405337755…058013286951`)
- Test index (integers 1..p): p itself (859-digit)
- r = p·‖p·π/10‖ = 0.53597893  (< 1 ✓)
- ‖p·π/10‖ = 6.068491e-860
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 883216099405337755…541776675230  (859 digits)
- Tests since previous: 883216099405337755…541776675230  (859 digits)
- Desert width: 883216099405337755…541776675229  (859 digits) consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 3690.2265

--- DESERT 9 END · DESERT 10 START ---

### PRIME #14 — 1025 digits  ·  [GIANT]
- Exact (1025 digits): see `data/desert_map.csv`  (`196819030242832262…591371595031`)
- Test index (integers 1..p): p itself (1025-digit)
- r = p·‖p·π/10‖ = 0.014760668  (< 1 ✓)
- ‖p·π/10‖ = 7.499614e-1027
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 196819030242832262…533358308080  (1025 digits)
- Tests since previous: 196819030242832262…533358308080  (1025 digits)
- Desert width: 196819030242832262…533358308079  (1025 digits) consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 6048.7507

--- DESERT 10 END · DESERT 11 START ---

### PRIME #15 — 1592 digits  ·  [GIANT]
- Exact (1592 digits): see `data/desert_map.csv`  (`529434903242710060…752677909607`)
- Test index (integers 1..p): p itself (1592-digit)
- r = p·‖p·π/10‖ = 0.98039594  (< 1 ✓)
- ‖p·π/10‖ = 1.851778e-1592
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 529434903242710060…161306314576  (1592 digits)
- Tests since previous: 529434903242710060…161306314576  (1592 digits)
- Desert width: 529434903242710060…161306314575  (1592 digits) consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 9713.8303

--- DESERT 11 END · DESERT 12 START ---

### PRIME #16 — 1863 digits  ·  [GIANT]
- Exact (1863 digits): see `data/desert_map.csv`  (`174943788961438175…864658557771`)
- Test index (integers 1..p): p itself (1863-digit)
- r = p·‖p·π/10‖ = 0.050490013  (< 1 ✓)
- ‖p·π/10‖ = 2.886071e-1864
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 174943788961438175…111980648164  (1863 digits)
- Tests since previous: 174943788961438175…111980648164  (1863 digits)
- Desert width: 174943788961438175…111980648163  (1863 digits) consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 14001.803

--- DESERT 12 END · DESERT 13 START ---

### PRIME #17 — 2272 digits  ·  [GIANT]
- Exact (2272 digits): see `data/desert_map.csv`  (`915117487968349622…086060269167`)
- Test index (integers 1..p): p itself (2272-digit)
- r = p·‖p·π/10‖ = 0.54575959  (< 1 ✓)
- ‖p·π/10‖ = 5.96382e-2273
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 915117487968349622…221401711396  (2272 digits)
- Tests since previous: 915117487968349622…221401711396  (2272 digits)
- Desert width: 915117487968349622…221401711395  (2272 digits) consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 19233.188

--- DESERT 13 END · DESERT 14 START ---

### PRIME #18 — 2389 digits  ·  [GIANT]
- Exact (2389 digits): see `data/desert_map.csv`  (`207163392083512332…013122521601`)
- Test index (integers 1..p): p itself (2389-digit)
- r = p·‖p·π/10‖ = 0.69314741  (< 1 ✓)
- ‖p·π/10‖ = 3.345897e-2389
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 207163392083512332…927062252434  (2389 digits)
- Tests since previous: 207163392083512332…927062252434  (2389 digits)
- Desert width: 207163392083512332…927062252433  (2389 digits) consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 24732.489

--- DESERT 14 END · DESERT 15 START ---

### PRIME #19 — 3428 digits  ·  [GIANT]
- Exact (3428 digits): see `data/desert_map.csv`  (`994698744384214170…698029440779`)
- Test index (integers 1..p): p itself (3428-digit)
- r = p·‖p·π/10‖ = 0.510571  (< 1 ✓)
- ‖p·π/10‖ = 5.132921e-3429
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 994698744384214170…684906919178  (3428 digits)
- Tests since previous: 994698744384214170…684906919178  (3428 digits)
- Desert width: 994698744384214170…684906919177  (3428 digits) consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 32625.746

--- DESERT 15 END · DESERT 16 START ---

### PRIME #20 — 3548 digits  ·  [GIANT]
- Exact (3548 digits): see `data/desert_map.csv`  (`127374706877116396…504644341493`)
- Test index (integers 1..p): p itself (3548-digit)
- r = p·‖p·π/10‖ = 0.027685303  (< 1 ✓)
- ‖p·π/10‖ = 2.173532e-3549
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 127374706877116396…806614900714  (3548 digits)
- Tests since previous: 127374706877116396…806614900714  (3548 digits)
- Desert width: 127374706877116396…806614900713  (3548 digits) consecutive non-exceptional integers
- C_unwt cumulative: 1.433677
- C_wt cumulative: 40793.257

## Notes
- **First desert (191 → P5)** is the headline void: 3993746143441 consecutive integers with zero exceptional primes.
- v1.6 (principal-convergent search, 4010-digit π) sees 14 of these 20; the 6 others are 5 semiconvergents + one large principal convergent (#20) above v1.6's precision ceiling.
- The circulated list `…291,317,607,…` is a `299+π` (not π/10) artifact; 291 = 3×97 is composite; only 2,3,19,191 of it actually pass. Verified and excluded per the task rule.
- Honesty: BPSW is not a formal primality proof for the 1000+ digit entries; this report proves no new mathematics.
