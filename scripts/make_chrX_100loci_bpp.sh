#!/bin/bash
set -euo pipefail

PROJECT=/mnt/yanglab-bignas/data2/zack/bpp_neanderthal_introgression
cd "$PROJECT"

WORK=work/chrX_100_alignment
OUTPHY=bpp/test_runs/input/YRI8_Altai.chrX.test100.phy
WINDOWS=$WORK/windows100.bed

REF=data/reference/human_g1k_v37.fasta
FAI=data/reference/human_g1k_v37.fasta.fai
YRI=data/modern/1000g/YRI8.chrX.vcf.gz
NEA=data/neanderthal/altai/AltaiNea.hg19_1000g.X.mod.vcf.gz
MASK=data/masks/strict_mask.X.bed

NAMES="NA18488_h1 NA18488_h2 NA18489_h1 NA18489_h2 NA18499_h1 NA18499_h2 NA18502_h1 NA18502_h2 NA18486_h1 NA18498_h1 NA18501_h1 NA18504_h1 AltaiNea"

rm -rf "$WORK"
mkdir -p "$WORK"
: > "$OUTPHY"

echo "Selecting first 100 x 10kb windows with >=9000 bp strict-mask coverage..."

awk -v W=10000 '
BEGIN{OFS="\t"}
$1=="X"{
  s=int($2/W);
  e=int(($3-1)/W);
  for(i=s;i<=e;i++){
    ws=i*W;
    we=(i+1)*W;
    os=($2>ws?$2:ws);
    oe=($3<we?$3:we);
    if(oe>os) acc[i]+=oe-os;
  }
}
END{
  for(i in acc){
    if(acc[i]>=9000){
      print "X", i*W, (i+1)*W, acc[i];
    }
  }
}
' "$MASK" | sort -k2,2n | head -n 100 > "$WINDOWS"

nwin=$(wc -l < "$WINDOWS")
echo "Selected windows: $nwin"
if [ "$nwin" -ne 100 ]; then
  echo "ERROR: expected 100 windows, got $nwin"
  exit 1
fi

locus=0

while read CHR START END ACC
do
  locus=$((locus+1))
  REGION="${CHR}:$((START+1))-${END}"
  LDIR="$WORK/locus_${locus}"
  mkdir -p "$LDIR/fastas" "$LDIR/vcfs"

  echo "===== Locus $locus / 100: $REGION, accessible bp = $ACC ====="

  python3 - << PY
from pathlib import Path

region = "$REGION"
chrom, coords = region.split(":")
start, end = map(int, coords.split("-"))

fasta = Path("$REF")
fai = Path("$FAI")
out = Path("$LDIR/ref.fa")

info = {}
with open(fai) as f:
    for line in f:
        fields = line.rstrip().split("\t")
        info[fields[0]] = {
            "length": int(fields[1]),
            "offset": int(fields[2]),
            "line_bases": int(fields[3]),
            "line_width": int(fields[4]),
        }

x = info[chrom]
need = end - start + 1
zero_based = start - 1
line_no = zero_based // x["line_bases"]
col = zero_based % x["line_bases"]
byte_pos = x["offset"] + line_no * x["line_width"] + col

seq_parts = []
n = 0
with open(fasta, "rb") as f:
    f.seek(byte_pos)
    while n < need:
        chunk = f.read(8192)
        if not chunk:
            break
        chunk = chunk.replace(b"\n", b"").replace(b"\r", b"")
        take = min(len(chunk), need - n)
        seq_parts.append(chunk[:take].decode("ascii"))
        n += take

seq = "".join(seq_parts)
if len(seq) != need:
    raise ValueError(f"Expected {need}, got {len(seq)}")

with open(out, "w") as f:
    f.write(f">{region}\n")
    for i in range(0, len(seq), 60):
        f.write(seq[i:i+60] + "\n")
PY

  reflen=$(grep -v '^>' "$LDIR/ref.fa" | tr -d '\n' | wc -c)
  if [ "$reflen" -ne 10000 ]; then
    echo "ERROR: reference length is $reflen, expected 10000"
    exit 1
  fi

  bcftools view -r "$REGION" -v snps -m2 -M2 "$YRI" \
    -Oz -o "$LDIR/vcfs/YRI8.snps.vcf.gz"
  bcftools index -f -t "$LDIR/vcfs/YRI8.snps.vcf.gz"

  bcftools view -r "$REGION" -v snps -m2 -M2 "$NEA" \
    -Oz -o "$LDIR/vcfs/AltaiNea.snps.vcf.gz"
  bcftools index -f -t "$LDIR/vcfs/AltaiNea.snps.vcf.gz"

  make_yri_consensus () {
    SAMPLE=$1
    HAP=$2
    OUTNAME=$3

    cat "$LDIR/ref.fa" | \
    bcftools consensus \
      -s "$SAMPLE" \
      -H "$HAP" \
      "$LDIR/vcfs/YRI8.snps.vcf.gz" \
    | sed "s/^>.*/>${OUTNAME}/" \
    > "$LDIR/fastas/${OUTNAME}.fa"
  }

  make_yri_consensus NA18488 1 NA18488_h1
  make_yri_consensus NA18488 2 NA18488_h2
  make_yri_consensus NA18489 1 NA18489_h1
  make_yri_consensus NA18489 2 NA18489_h2
  make_yri_consensus NA18499 1 NA18499_h1
  make_yri_consensus NA18499 2 NA18499_h2
  make_yri_consensus NA18502 1 NA18502_h1
  make_yri_consensus NA18502 2 NA18502_h2

  make_yri_consensus NA18486 1 NA18486_h1
  make_yri_consensus NA18498 1 NA18498_h1
  make_yri_consensus NA18501 1 NA18501_h1
  make_yri_consensus NA18504 1 NA18504_h1

  cat "$LDIR/ref.fa" | \
  bcftools consensus \
    -s AltaiNea \
    -H 1 \
    "$LDIR/vcfs/AltaiNea.snps.vcf.gz" \
  | sed "s/^>.*/>AltaiNea/" \
  > "$LDIR/fastas/AltaiNea.fa"

  python3 - << PY
from pathlib import Path

names = "$NAMES".split()
indir = Path("$LDIR/fastas")
out = Path("$OUTPHY")

records = []
for name in names:
    f = indir / f"{name}.fa"
    if not f.exists():
        raise FileNotFoundError(f"Missing {f}")
    seq = []
    with open(f) as handle:
        for line in handle:
            line = line.strip()
            if line and not line.startswith(">"):
                seq.append(line.upper())
    records.append((name, "".join(seq)))

lengths = {len(seq) for _, seq in records}
if len(lengths) != 1:
    raise ValueError(f"Locus $locus inconsistent lengths: {sorted(lengths)}")

L = lengths.pop()
if L != 10000:
    raise ValueError(f"Locus $locus length is {L}, expected 10000")

with open(out, "a") as handle:
    handle.write(f"{len(records)} {L}\n")
    for name, seq in records:
        handle.write(f"{name}^{name}  {seq}\n")

print(f"Appended locus $locus: {len(records)} sequences, {L} bp")
PY

done < "$WINDOWS"

echo
echo "===== Finished 100 loci ====="
echo "Output: $OUTPHY"
echo "Locus blocks:"
grep -c '^13 10000$' "$OUTPHY"
echo "Line count:"
wc -l "$OUTPHY"
echo "File size:"
ls -lh "$OUTPHY"
