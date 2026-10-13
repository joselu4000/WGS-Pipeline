# Listeria monocytogenes WGS Analysis Pipeline

Reproducible Bash-based workflow for whole-genome sequencing analysis of *Listeria monocytogenes* isolates.

The pipeline performs paired-end read preprocessing and quality control, genome analysis with TORMES, plasmid detection with PlasmidFinder, and targeted BLASTn screening of biofilm-associated and truncated/partial genes.

## Requirements

The workflow is designed for Linux systems and uses Conda for dependency management.

The validated software environment includes:

- TORMES 1.3.0
- Python 3.6.11
- Perl 5.26.2
- FastQC 0.12.1
- fastp 1.1.0
- BLAST+ 2.10.1
- PlasmidFinder 2.1.1
- KMA 1.4.15
- Biopython 1.77
- cgecore 1.5.6

The required bioinformatics dependencies and validated versions are defined in `environment.yml`.

Standard Linux command-line utilities such as `bash`, `sed`, `awk`, `grep`, `sort`, `cut`, and `gunzip` are also required.

## Installation

Clone the repository and enter the project directory:

```bash
git clone https://github.com/joselu4000/WGS-Pipeline.git
cd WGS-Pipeline
```

Alternatively, download the repository and enter its root directory.

Create the Conda environment:

```bash
conda env create -f environment.yml
```

Activate it:

```bash
conda activate listeria-wgs-pipeline
```

The environment defined in `environment.yml` has been tested by rebuilding it from scratch on Linux.

## Database setup

Before running the pipeline, generate the local BLAST database and download/index the PlasmidFinder database:

```bash
./setup_databases.sh
```

The setup script performs the following tasks:

1. builds `Codes-sh/BLASTn/genes_db` from `Codes-sh/BLASTn/BGRD_sequences.fasta`;
2. downloads the PlasmidFinder database;
3. checks out the validated PlasmidFinder database commit:

```text
07648fddc4c6cf0330c9fc041dd6f52b4a69f8d6
```

corresponding to tag:

```text
plasmidfinder-3.0.3
```

4. builds the KMA indexes required by PlasmidFinder.

Generated databases are excluded from version control and can be reconstructed using `setup_databases.sh`.

## Input data

Create the raw sequencing data directory:

```bash
mkdir -p Strains-raw
```

Each isolate must initially be stored in its own directory inside `Strains-raw/`.

For example:

```text
Strains-raw/
├── original_folder_001/
│   ├── sequencing_R1.fastq.gz
│   └── sequencing_R2.fastq.gz
├── original_folder_002/
│   ├── sequencing_R1.fastq.gz
│   └── sequencing_R2.fastq.gz
├── IDs-Correspondences.txt
└── METADATA.txt
```

FASTQ filenames must contain `R1` or `R2` so that paired reads can be identified automatically.

Compressed `.fastq.gz` and uncompressed `.fastq` input files can be processed.

## Sample ID correspondence

A template is provided in:

```text
IDs-Correspondences_template.txt
```

Copy it into the raw-data directory:

```bash
cp IDs-Correspondences_template.txt Strains-raw/IDs-Correspondences.txt
```

Example:

```text
New_ID	Original_ID
SAMPLE_001	original_folder_001
SAMPLE_002	original_folder_002
```

The file must be tab-separated.

`New_ID` is the standardized sample identifier used throughout the analysis.

`Original_ID` must correspond to the original directory name containing the sequencing reads.

During the first pipeline stage, isolate directories and sequencing files are standardized according to this correspondence.

The paired-end reads are ultimately represented as:

```text
<New_ID>_R1.fastq
<New_ID>_R2.fastq
```

## Metadata

A metadata template is provided in:

```text
METADATA_template.txt
```

Copy it into the raw-data directory:

```bash
cp METADATA_template.txt Strains-raw/METADATA.txt
```

Example:

```text
Sample	Type	Source	Industry	Description
SAMPLE_001	surface	food	industry_A	description
SAMPLE_002	clinical	clinical	hospital	description
```

The file must be tab-separated.

The first column contains the sample identifier and must match the `New_ID` column in `IDs-Correspondences.txt`.

The pipeline automatically generates the absolute `Read1` and `Read2` paths required by TORMES from the processed paired-end reads.

The resulting TORMES metadata structure is generated internally as:

```text
Samples	Read1	Read2	Type	Source	Industry	Description
```

Additional metadata columns present after the first column are retained.

Only samples for which both processed paired-end FASTQ files are available are included in the metadata passed to TORMES.

## Running the pipeline

Make sure the Conda environment is active:

```bash
conda activate listeria-wgs-pipeline
```

Then execute:

```bash
./Pipeline-Guidelines.sh
```

The workflow performs the following stages:

1. sample directory and FASTQ filename standardization;
2. FASTQ decompression and initial FastQC analysis;
3. read preprocessing with fastp;
4. additional quality trimming with Prinseq;
5. post-trimming FastQC analysis;
6. genome analysis with TORMES;
7. plasmid detection with PlasmidFinder;
8. consolidation of PlasmidFinder results;
9. BLASTn screening of biofilm-associated genes;
10. consolidation of biofilm-associated BLASTn results;
11. BLASTn screening of truncated/partial genes.

## Existing output directories

For safety, the complete pipeline does not automatically remove results from previous executions.

If any of the main output directories already exists, the workflow stops before beginning a new complete run.

Previous outputs should therefore be moved, archived, or removed manually before starting another run.

## Main output directories

The workflow generates the following main directories:

```text
fastp/
fastq_trim/
tormes_output/
plasmid_output/
BLASTn-output/
```

These directories contain generated results and are excluded from version control.

### fastp

Contains the paired-end reads processed with fastp and the corresponding fastp reports.

### fastq_trim

Contains the final quality-trimmed FASTQ files used by TORMES.

The expected structure for each sample is:

```text
fastq_trim/
└── SAMPLE_001/
    ├── SAMPLE_001_R1_trim_q30.fastq
    └── SAMPLE_001_R2_trim_q30.fastq
```

### tormes_output

Contains the output generated by TORMES.

TORMES is executed using:

```text
--min_len 100
```

### plasmid_output

Contains the individual PlasmidFinder results.

### BLASTn-output

Contains the targeted BLASTn screening results.

Important consolidated output files include:

```text
BLASTn-output/all_samples_blast_summary.csv
BLASTn-output/all_samples_truncados_summary.csv
```

## Targeted BLAST resources

The repository includes the source files required for the targeted genomic screening:

```text
Codes-sh/BLASTn/BGRD_sequences.fasta
Codes-sh/BLASTn/biofilm_G.txt
Codes-sh/BLASTn/truncados.fasta
```

`BGRD_sequences.fasta` is used by `setup_databases.sh` to construct the local BLAST nucleotide database:

```text
Codes-sh/BLASTn/genes_db
```

`biofilm_G.txt` defines the locus tags retained during the biofilm-associated gene screening.

`truncados.fasta` contains the reference sequences used for the additional truncated/partial gene screening.

Generated BLAST database files are intentionally excluded from the repository.

## Repository structure

```text
Pipeline/
├── Codes-sh/
│   ├── BLASTn/
│   │   ├── BGRD_sequences.fasta
│   │   ├── biofilm_G.txt
│   │   └── truncados.fasta
│   ├── BLASTn-Biofilm.sh
│   ├── BLASTn-Truncated.sh
│   ├── Cleaning-fastp.sh
│   ├── Descomprime.sh
│   ├── FastQC-trim.sh
│   ├── Plasmid-Finder.sh
│   ├── Rename-Correction.sh
│   ├── Sumup-BLASTn.sh
│   ├── SumUP-plasmid.sh
│   ├── TORMES-subpipeline.sh
│   └── Trimado-dobleOpt-q30.sh
├── IDs-Correspondences_template.txt
├── METADATA_template.txt
├── Pipeline-Guidelines.sh
├── environment.yml
├── prinseq-lite.pl
├── setup_databases.sh
├── .gitignore
└── README.md
```

The following directories and files are generated locally and are not tracked by Git:

```text
Strains-raw/
databases/
fastp/
fastq_trim/
tormes_output/
plasmid_output/
BLASTn-output/
Codes-sh/BLASTn/genes_db.*
```

## Reproducibility

The software environment was validated by creating a new Conda environment directly from `environment.yml` and confirming the expected versions of TORMES, FastQC, fastp, BLAST+, KMA, PlasmidFinder, Python, and associated dependencies.

The database setup was independently tested from the reconstructed environment.

The local BLAST database was regenerated successfully from `BGRD_sequences.fasta`, containing 2,867 reference sequences.

The PlasmidFinder database was downloaded, fixed to the validated commit, and successfully indexed with KMA.

Raw sequencing data, study-specific metadata, generated databases, pipeline outputs, logs, and temporary files are intentionally excluded from version control.

## Notes

The scripts are intended to be executed from the root directory of the repository.

The workflow assumes paired-end sequencing data.

Sample identifiers should not contain whitespace.

The same standardized sample identifier must be used consistently between:

- `IDs-Correspondences.txt`;
- `METADATA.txt`;
- the processed FASTQ filenames generated by the workflow.

## Citation

If this pipeline is used in a scientific publication, please cite the associated study and the original software tools used by the workflow.

A specific citation for the associated study will be added after publication.

## Reference sequence provenance

Reference nucleotide sequences distributed with this repository were obtained
from public NCBI nucleotide resources. Original accession numbers and sequence
annotations are retained in the FASTA headers whenever available.

`Codes-sh/BLASTn/BGRD_sequences.fasta` contains coding sequences derived from
the *Listeria monocytogenes* EGD-e reference chromosome (NCBI RefSeq accession
`NC_003210.1`). The FASTA headers retain the corresponding locus tags, Gene IDs,
protein identifiers, and genomic coordinates.

`Codes-sh/BLASTn/truncados.fasta` contains reference sequences selected for the
additional truncated/partial gene screening. The original NCBI accession numbers,
gene names, organisms, and Gene IDs are retained in the sequence headers.

`Codes-sh/BLASTn/biofilm_G.txt` is the curated gene-selection table used by this
workflow to identify the targeted biofilm-associated loci. It includes NCBI Gene
IDs and *L. monocytogenes* EGD-e locus tags where applicable.

NCBI places no restrictions on the use or distribution of GenBank molecular
sequence data, although individual submitters may retain rights in particular
submitted records. These reference sequence data are therefore not relicensed
under the MIT License applied to the original code and documentation of this
repository.

## Third-party software

This repository includes `prinseq-lite.pl` (PRINSEQ-lite v0.20.4), developed by Robert Schmieder.

PRINSEQ-lite is distributed under the GNU General Public License, version 3 or later.

The original copyright and license notice are retained in `prinseq-lite.pl`. A copy of the GNU GPL v3 is provided in:

LICENSES/PRINSEQ-GPL-3.0.txt

## License

Original code and documentation in this repository are distributed under the MIT License. See `LICENSE`.

Third-party components retain their respective licenses. In particular, `prinseq-lite.pl` is distributed under the GNU General Public License version 3 or later; see `LICENSES/PRINSEQ-GPL-3.0.txt`.
