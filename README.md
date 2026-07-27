# BPP Input Preparation

BPP requires:

1. Multilocus sequence alignment
2. Imap file
3. Control file

## 1. Required Data

### Reference genome

Downloaded:

```text
data/reference/human_g1k_v37.fasta
data/reference/human_g1k_v37.fasta.fai
```

Assembly:

```text
GRCh37 / hg19
```

Source:

[https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/](https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/)

### Modern-human VCF files

Eight YRI samples from 1000 Genomes chromosome X have been downloaded.

Public source:

[https://www.internationalgenome.org/data-portal/sample](https://www.internationalgenome.org/data-portal/sample)

Data used in the reference paper require authorized access:

[https://dbgap.ncbi.nlm.nih.gov/beta/study/phs001396.v1.p1/#authorized-data-access-requests](https://dbgap.ncbi.nlm.nih.gov/beta/study/phs001396.v1.p1/#authorized-data-access-requests)

SGDP is another possible source with more diverse African populations, including YRI, ESN, MSL, LMK, and GMD, but reference-genome compatibility must be checked.

[https://reichdata.hms.harvard.edu/pub/datasets/sgdp/](https://reichdata.hms.harvard.edu/pub/datasets/sgdp/)

Sample metadata and VCF indexes are also required.

### Neanderthal VCF files

Altai has been downloaded for the main analysis.

Chagyrskaya and Vindija may be used for replication.

Sources:

- [https://www.eva.mpg.de/genetics/genome-projects/neandertal/](https://www.eva.mpg.de/genetics/genome-projects/neandertal/)
- [https://ftp.eva.mpg.de/neandertal/altai/AltaiNeandertal/VCF/](https://ftp.eva.mpg.de/neandertal/altai/AltaiNeandertal/VCF/)
- [https://ftp.eva.mpg.de/neandertal/Chagyrskaya/VCF/](https://ftp.eva.mpg.de/neandertal/Chagyrskaya/VCF/)
- [http://cdna.eva.mpg.de/neandertal/Vindija/VCF/Vindija33.19/](http://cdna.eva.mpg.de/neandertal/Vindija/VCF/Vindija33.19/)

### Callable mask

Downloaded:

```text
data/masks/20141020.strict_mask.whole_genome.bed
data/masks/strict_mask.chrX.bed
data/masks/strict_mask.X.bed
```

Source:

[https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/supporting/accessible_genome_masks/](https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/supporting/accessible_genome_masks/)

The mask defines regions considered reliable under the 1000 Genomes accessibility criteria.

A missing VCF record should only be treated as the reference allele when the site is callable. Otherwise, the site should be masked as `N`, or the locus should be removed.

## 2. Region Partitioning

The callable mask defines technical reliability. The following annotations have been downloaded to separate putatively neutral, exonic, and regulatory regions.

### Directory structure

```text
data/
├── annotations/
│   ├── gencode/
│   ├── regulatory/
│   ├── conservation/
│   └── optional_masks/
├── masks/
└── windows/
    ├── neutral/
    ├── exon/
    └── regulatory/
```

### Annotation sources

| Annotation | Purpose | Downloaded file | Source |
|---|---|---|---|
| GENCODE v19 | Identify exons and UTRs | `data/annotations/gencode/gencode.v19.annotation.gtf.gz` | [https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_19/gencode.v19.annotation.gtf.gz](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_19/gencode.v19.annotation.gtf.gz) |
| ENCODE cCREs | Identify candidate regulatory elements | `data/annotations/regulatory/ENCFF788SJC.bed.gz` | [https://www.encodeproject.org/files/ENCFF788SJC/](https://www.encodeproject.org/files/ENCFF788SJC/) |
| phastCons 100-way | Identify conserved elements | `data/annotations/conservation/phastConsElements100way.txt.gz` | [https://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/phastConsElements100way.txt.gz](https://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/phastConsElements100way.txt.gz) |
| RepeatMasker | Optional repeat exclusion | `data/annotations/optional_masks/rmsk.txt.gz` | [https://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/rmsk.txt.gz](https://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/rmsk.txt.gz) |
| Segmental duplications | Optional duplication exclusion | `data/annotations/optional_masks/genomicSuperDups.txt.gz` | [https://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/genomicSuperDups.txt.gz](https://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/genomicSuperDups.txt.gz) |
| 100-mer mappability | Optional mappability filter | `data/annotations/optional_masks/wgEncodeCrgMapabilityAlign100mer.bigWig` | [https://hgdownload.soe.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeMapability/](https://hgdownload.soe.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeMapability/) |
| GRCh37 PAR regions | Exclude pseudoautosomal regions from chromosome-X analysis | `data/annotations/optional_masks/GRCh37_PAR.bed` | [https://www.ncbi.nlm.nih.gov/grc/human](https://www.ncbi.nlm.nih.gov/grc/human) |

The downloaded gzip files passed integrity checks. The mappability file has a valid BigWig header.

### Partition definitions

#### Putatively neutral noncoding regions

```text
strict callable mask
− exons
− UTRs
− ENCODE regulatory elements
− conserved elements
− chromosome-X PAR regions
```

RepeatMasker, segmental duplications, and low-mappability regions may be added as stricter filters.

Output:

```text
data/windows/neutral/autosomes.5kb.50kb_gap.bed
data/windows/neutral/chrX.5kb.50kb_gap.bed
```

Planned sampling:

- Locus length: 5 kb
- Approximately 50 kb between loci
- Identical filtering rules for autosomes and chromosome X

#### Exon regions

Defined using GENCODE v19 features labelled as `exon`.

Output:

```text
data/windows/exon/autosomes.exon.bed
data/windows/exon/chrX.exon.bed
```

#### Regulatory regions

Defined using ENCODE candidate cis-regulatory elements.

Output:

```text
data/windows/regulatory/autosomes.ccre.bed
data/windows/regulatory/chrX.ccre.bed
```

### Coordinate rules

All processed BED files must use:

```text
0-based, half-open coordinates
```

GENCODE GTF coordinates are 1-based and must be converted before BED operations.

Chromosome names must match the current reference and VCF files:

```text
1, 2, ..., 22, X
```

Files using `chr1` or `chrX` must be normalized before intersection.

## 3. Alignment Workflow

```text
Reference FASTA
        +
Sample VCF files
        +
Callable and annotation masks
        ↓
Define genomic partitions
        ↓
Select loci
        ↓
Construct per-sample consensus sequences
        ↓
Mask unreliable bases as N
        ↓
One window = one locus alignment
        ↓
Combine loci into a BPP multilocus alignment
```

## 4. Current Test Data

Current chromosome-X test windows:

```text
work/test10_alignment/windows10.bed
work/chrX_100_alignment/windows100.bed
```

These are 10-kb test windows selected using the strict mask. They are not the final 5-kb putatively neutral loci.

Current BPP alignments:

```text
bpp/test_runs/input/YRI8_Altai.chrX.test1.phy
bpp/test_runs/input/YRI8_Altai.chrX.test10.phy
bpp/test_runs/input/YRI8_Altai.chrX.test100.phy
```

Each test locus contains:

- 12 YRI chromosome-X haplotypes
- 1 Altai Neanderthal sequence

## 5. Imap File

Completed:

```text
bpp/test_runs/input/YRI8_Altai.chrX.Imap.txt
```

This maps the YRI haplotypes to YRI and the Altai sequence to Neanderthal.

## 6. Control Files

### MSC test

Control file:

```text
bpp/test_runs/A00_readtest/r1/test10.A00.ctl
```

Settings:

```text
speciesdelimitation = 0
speciestree = 0
```

Tree:

```text
(YRI, Neanderthal);
```

Priors:

```text
thetaprior = 3 0.002 e
tauprior = 3 0.002
```

The preliminary test uses `IG(3, 0.002)`, with prior mean 0.001. These settings are for format testing and may be adjusted for the final analysis.

### MSC-I test

Location:

```text
bpp/test_runs/MSCi_test/
```

Model:

```text
species&tree = 2 YRI Neanderthal
12 1
((YRI,Y[&phi=0.050000])X,(Neanderthal,X[&phi=0.050000])Y)R;
```

`X` and `Y` are internal hybrid nodes. The `phi = 0.05` values are starting values, not fixed estimates.

Prior:

```text
phiprior = 1 1
```

This assigns a uniform `Beta(1,1)` prior to the introgression probability. The prior should be reviewed through sensitivity analysis before final biological interpretation.
