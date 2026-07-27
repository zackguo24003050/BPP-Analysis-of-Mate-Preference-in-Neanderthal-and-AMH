import sys
from pathlib import Path

fastadir = Path(sys.argv[1])
outphy = Path(sys.argv[2])

names = [
    "NA18488_h1", "NA18488_h2",
    "NA18489_h1", "NA18489_h2",
    "NA18499_h1", "NA18499_h2",
    "NA18502_h1", "NA18502_h2",
    "NA18486_h1", "NA18498_h1",
    "NA18501_h1", "NA18504_h1",
    "AltaiNea"
]

records = []
for name in names:
    fa = fastadir / f"{name}.fa"
    seq = []
    with open(fa) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith(">"):
                seq.append(line.upper())
    seq = "".join(seq)
    records.append((name, seq))

lengths = set(len(seq) for _, seq in records)
if lengths != {10000}:
    raise SystemExit(f"ERROR: bad sequence lengths: {lengths}")

with open(outphy, "a") as f:
    f.write("13 10000\n")
    for name, seq in records:
        f.write(f"{name}^{name}  {seq}\n")
