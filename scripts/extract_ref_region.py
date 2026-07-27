import sys
from pathlib import Path

ref, fai, chrom, start, end, out = sys.argv[1:]
start = int(start)
end = int(end)

info = {}
with open(fai) as f:
    for line in f:
        a = line.rstrip().split("\t")
        info[a[0]] = (int(a[1]), int(a[2]), int(a[3]), int(a[4]))

length, offset, line_bases, line_width = info[chrom]

need = end - start + 1
pos0 = start - 1
line_no = pos0 // line_bases
col = pos0 % line_bases
byte_pos = offset + line_no * line_width + col

seq = []
n = 0
with open(ref, "rb") as f:
    f.seek(byte_pos)
    while n < need:
        chunk = f.read(8192)
        if not chunk:
            break
        chunk = chunk.replace(b"\n", b"").replace(b"\r", b"")
        take = min(len(chunk), need - n)
        seq.append(chunk[:take].decode())
        n += take

seq = "".join(seq)
if len(seq) != need:
    raise SystemExit(f"ERROR: expected {need}, got {len(seq)}")

with open(out, "w") as f:
    f.write(f">{chrom}:{start}-{end}\n")
    for i in range(0, len(seq), 60):
        f.write(seq[i:i+60] + "\n")
