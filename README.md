# BPP Input Preparation

BPP requires three input files:

1. Multilocus sequence alignment file
2. Imap file
3. Control file

## 1. Multilocus Sequence Alignment

### Required data

#### Reference genome

Downloaded in:

```text
data/reference/
```

Example:

```text
GRCh37.fa
```

The reference genome provides bases for invariant sites.

Source:

https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/

#### Modern-human VCF files

Eight YRI samples from 1000 Genomes chromosome X have been downloaded.

The data used in the paper require authorized access:

https://dbgap.ncbi.nlm.nih.gov/beta/study/phs001396.v1.p1/#authorized-data-access-requests

Possible alternative public sources:

**1000 Genomes Project**

More standardized, but contains fewer African populations.

https://www.internationalgenome.org/data-portal/sample

**Simons Genome Diversity Project**

Contains 279 samples and more diverse African populations, but uses a different reference genome.

https://reichdata.hms.harvard.edu/pub/datasets/sgdp/

Candidate populations:

```text
YRI ESN MSL LMK GMD
```

Sample metadata are also required.

#### Neanderthal VCF files

Altai has been downloaded for the main analysis.

Chagyrskaya and Vindija may be used for replication.

Sources:

- https://www.eva.mpg.de/genetics/genome-projects/neandertal/
- https://ftp.eva.mpg.de/neandertal/altai/AltaiNeandertal/VCF/
- https://ftp.eva.mpg.de/neandertal/Chagyrskaya/VCF/
- http://cdna.eva.mpg.de/neandertal/Vindija/VCF/Vindija33.19/

#### Callable masks

Callable or mask BED files define reliable genomic regions.

A missing VCF record should only be treated as the reference allele when the site is callable. Otherwise, the site should be masked as `N`, or the window should be removed.

#### VCF indexes

Each VCF file requires an index file.

### Current data

The current dataset contains:

- Eight YRI samples
- A strict mask
- A reference genome
- Altai Neanderthal data

The VCF records bases that differ from the reference genome. The mask identifies reliable regions, while the reference FASTA provides the complete reference sequence.

### Processing workflow

```text
Reference FASTA
        +
Sample VCF
        ↓
Per-sample consensus sequences
        ↓
Select reliable windows using the strict mask
        ↓
Extract the same windows from all samples
        ↓
One window = one locus alignment
        ↓
Combine loci into a multilocus BPP alignment
```

Current window size:

```text
10 kb
```

## 2. Imap File

The Imap file for eight YRI samples and Altai Neanderthal is complete.

Location:

```text
/mnt/yanglab-bignas/data2/zack/bpp_neanderthal_introgression/bpp/test_runs/input/
```

## 3. Control Files

### MSC test

Control file:

```text
bpp/test_runs/A00_readtest/r1/test10.A00.ctl
```

Dataset:

- 10 chromosome-X loci
- One 10-kb window per locus
- 13 sequences per locus
- 12 YRI chromosome-X haplotypes
- 1 Altai Neanderthal sequence

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

Theta and tau are positive mutation-scaled parameters. The preliminary test uses inverse-gamma priors:

```text
IG(3, 0.002)
```

The prior mean is 0.001. This broad prior is reasonable for a preliminary read test using closely related human and Neanderthal sequences, but it may need adjustment for the final introgression analysis.

### MSC-I test

Location:

```text
/mnt/yanglab-bignas/data2/zack/bpp_neanderthal_introgression/bpp/test_runs/MSCi_test/
```

Model:

```text
species&tree = 2 YRI Neanderthal
12 1
((YRI,Y[&phi=0.050000])X,(Neanderthal,X[&phi=0.050000])Y)R;
```

This is a fixed two-population MSC-I model with YRI and Neanderthal.

The extended Newick network contains one bidirectional introgression event. `X` and `Y` are internal hybrid nodes used by BPP.

The values:

```text
phi = 0.05
```

are starting values, not fixed final estimates.

Prior:

```text
phiprior = 1 1
```

This assigns a uniform `Beta(1,1)` prior to the introgression probability. It is appropriate for an initial MSC-I validation run, but should be reviewed through sensitivity analysis before final biological interpretation.
