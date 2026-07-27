#!/bin/bash
set -euo pipefail

PROJECT=/mnt/yanglab-bignas/data2/zack/bpp_neanderthal_introgression
cd "$PROJECT"

WORK=work/chrX_100_alignment
WINDOWS=$WORK/windows100.bed
PLAN=$WORK/sample_plan.tsv

REF=data/reference/human_g1k_v37.fasta
FAI=data/reference/human_g1k_v37.fasta.fai
YRI=data/modern/1000g/YRI8.chrX.vcf.gz
NEA=data/neanderthal/altai/AltaiNea.hg19_1000g.X.mod.vcf.gz

OUTPHY=bpp/test_runs/input/YRI8_Altai.chrX.test100.phy

rm -f "$OUTPHY"
: > "$OUTPHY"

locus=0

while read CHR START END ACC
do
  locus=$((locus+1))
  REGION="${CHR}:$((START+1))-${END}"
  LDIR="$WORK/locus_${locus}"

  mkdir -p "$LDIR/vcfs" "$LDIR/fastas"

  echo "===== locus $locus / 100: $REGION ====="

  python3 scripts/extract_ref_region.py \
    "$REF" "$FAI" "$CHR" "$((START+1))" "$END" "$LDIR/ref.fa"

  bcftools view -r "$REGION" -v snps -m2 -M2 "$YRI" \
    -Oz -o "$LDIR/vcfs/YRI8.snps.vcf.gz"
  bcftools index -f -t "$LDIR/vcfs/YRI8.snps.vcf.gz"

  bcftools view -r "$REGION" -v snps -m2 -M2 "$NEA" \
    -Oz -o "$LDIR/vcfs/AltaiNea.snps.vcf.gz"
  bcftools index -f -t "$LDIR/vcfs/AltaiNea.snps.vcf.gz"

  while read SAMPLE HAP OUTNAME
  do
    bcftools consensus \
      -f "$LDIR/ref.fa" \
      -s "$SAMPLE" \
      -H "$HAP" \
      "$LDIR/vcfs/YRI8.snps.vcf.gz" \
    | sed "s/^>.*/>${OUTNAME}/" \
    > "$LDIR/fastas/${OUTNAME}.fa"
  done < "$PLAN"

  bcftools consensus \
    -f "$LDIR/ref.fa" \
    -s AltaiNea \
    -H 1 \
    "$LDIR/vcfs/AltaiNea.snps.vcf.gz" \
  | sed "s/^>.*/>AltaiNea/" \
  > "$LDIR/fastas/AltaiNea.fa"

  python3 scripts/append_locus_to_phylip.py "$LDIR/fastas" "$OUTPHY"

done < "$WINDOWS"

echo "DONE"
grep -c '^13 10000$' "$OUTPHY"
wc -l "$OUTPHY"
ls -lh "$OUTPHY"
