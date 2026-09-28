# Overview
Workflow for NGS data analysis

This repository contains source code. The contents of this repository are 100% open source and released under the GPL-3.0 license (see [LICENSE.TXT](https://github.com/lakieungocquyet/ngs-pipeline/blob/main/LICENSE)).


# Requirements
*   Unix-like operating system (cannot run on Windows)

# Installation

## Build from source

### 1. Install [pixi](https://pixi.prefix.dev/latest/)

Pixi is a package and environment management tool. `ngs-pipeline` uses Pixi to manage dependencies and tasks.

To install pixi you can run the following command in your terminal:

```
curl -fsSL https://pixi.sh/install.sh | sh
```
If your system doesn't have `curl`, you can use `wget`:

```
wget -qO- https://pixi.sh/install.sh | sh
```


### 2. Clone the repository from GitHub

```
git clone https://github.com/lakieungocquyet/ngs-pipeline.git
```

### 3. Run installer

```
cd ngs-pipeline && source install.sh
```
## Using [Docker](https://www.docker.com/)

### Pulling the images
The Docker images for `ngs-pipeline` are available on [GitHub Container Registry (GHCR)](https://github.com/lakieungocquyet/ngs-pipeline/pkgs/container/ngs-pipeline).

To pull the latest image, run:

```
docker pull ghcr.io/lakieungocquyet/ngs-pipeline:latest
```

To pull a specific version, replace `latest` with the desired version tag:
```
BIN_VERSION="v0.1.0"

docker pull ghcr.io/lakieungocquyet/ngs-pipeline:${BIN_VERSION}
```

# How to use
### 1. Prepare input data
Prepare your NGS raw data (typically FASTQ files). 

Example:

```
home/
└──user/
    └──NGS_samples/
        ├── sample01/
        │   ├── sample1.R1.fastq.gz
        │   └── sample1.R2.fastq.gz
        └── sample02/
            ├── sample2.R1.fastq.gz
            └── sample2.R2.fastq.gz
```
### 2. Configure input parameters (YAML)

`ngs-pipeline` uses a YAML configuration file to define the input samples.

Example: `run.yaml`

```yaml
# Please don't use tab characters for indentation in this file. Use spaces only.
sample: [
  {
    id: sample01,
    read1: /home/user/NGS_samples/sample01/sample01_1.trim.fastq.gz,
    read2: /home/user/NGS_samples/sample01/sample01_2.trim.fastq.gz
  },
  {
    id: sample02,
    read1: /home/user/NGS_samples/sample02/sample02_1.trim.fastq.gz,
    read2: /home/user/NGS_samples/sample02/sample02_2.trim.fastq.gz
  },
  # You can add more samples as needed
  # {
  #   id: ,
  #   read1: ,
  #   read2:
  # },
]
```

#### Configuration details

The YAML configuration file includes:

- `sample`: list of samples with their file paths

Fields:

- `id`: unique sample identifier
- `read1`, `read2`: paths to paired-end FASTQ files

### 3. Run the variant calling pipeline

Example:

```bash
ngs-pipeline call-variants \
    -I ~/ngs-pipeline/example/run.yaml \
    -O ~/ngs-pipeline/results \
    -R ~/ngs-pipeline/resources/hg19/reference_genome_hg19/hg19.p13.plusMT.no_alt_analysis_set.fa \
    -r ~/ngs-pipeline/resources/hg19/regions_hg19/s07604624_hg19/s07604624_covered.bed \
    --variant-types snp indel cnv \
    --sequencing-platform illumina \
    --bqsr-known-sites \
        ~/ngs-pipeline/resources/hg19/variant_resources_hg19/1000g_phase1_indels_hg19/1000G_phase1.indels.hg19.sites.vcf.bgz \
        ~/ngs-pipeline/resources/hg19/variant_resources_hg19/dbsnp_138_hg19/dbsnp_138.hg19.vcf.bgz \
        ~/ngs-pipeline/resources/hg19/variant_resources_hg19/1000g_omni2_5_hg19/1000G_omni2.5.hg19.sites.vcf.bgz \
    --standard-annotation-resources \
        dbsnp138:~/ngs-pipeline/resources/hg19/variant_resources_hg19/dbsnp_138_hg19/dbsnp_138.hg19.vcf.bgz \
        clinvar:~/ngs-pipeline/resources/hg19/variant_resources_hg19/clinvar_20240716_hg19/clinvar_20240716.hg19.vcf.bgz \
        dbnsfp:~/ngs-pipeline/resources/hg19/variant_resources_hg19/dbnsfp4_9a_hg19/dbnsfp4.9a_hg19.txt.bgz \
        esp6500:~/ngs-pipeline/resources/hg19/variant_resources_hg19/esp6500si_v2_ssa137_hg19/esp6500si_v2_ssa137.hg19.vcf.bgz \
        1000g-phase3:~/ngs-pipeline/resources/hg19/variant_resources_hg19/1000g_phase3_v4_20130502_sites_hg19/1000G_phase3_v4_20130502.sites.hg19.vcf.bgz \
    -t 8 \
    --min-memory 8 \
    --max-memory 20
```

Results are written to a timestamped subdirectory of the `-O` path, e.g. `~/ngs-pipeline/results/2026-09-28_10h-30m-00s_UTC_call-variants/`.
# Commands

`ngs-pipeline` provides commands for analyzing sequencing data. You can access help from the command line with the `--help` flag:

```
ngs-pipeline --help
```

## `ngs-pipeline`

| Command | Description |
|---------|-------------|
| `call-variants` | Run variant calling pipeline |
| `--help` | Show help message for `ngs-pipeline` and exit |

* `ngs-pipeline call-variants`

```
About: Run variant calling pipeline
Usage:

       ngs-pipeline call-variants [arguments]

Arguments:

    -I, --input <YAML>
        Path to the YAML configuration file (e.g., run.yaml)

    -O, --output <DIR>
        Path to the directory where results will be stored (e.g., ~/result/)

    -R, --reference-genome <FASTA>
        Path to the reference genome FASTA file (e.g. hg19.fa)

    -r, --regions <BED>
        Path to genomic regions to process. Accepts BED file

    --bqsr-known-sites <LIST> [<VCF> ...]
        List of known sites for Base Quality Score Recalibration (e.g., dbsnp.vcf.gz mills.vcf.gz)

    --variant-types <TYPE> [<TYPE> ...]
        One or more variant types to call, separated by a space. Allowed values: snp, indel, cnv, all (default: all)

    --sequencing-platform <PLATFORM>
        Sequencing platform of all samples. Allowed values: illumina, nanopore, pacbio (default: illumina)

    --standard-annotation-resources <resource_name>:<file_path> [<resource_name>:<file_path> ...]
        One or more annotation resource databases, each given as <resource_name>:<file_path>, separated by a space.

        Only the following <resource_name>:<file_path> values are accepted:

            dbsnp138:<VCF>        dbSNP build 138 variant database
            clinvar:<VCF>         ClinVar clinical significance annotations
            esp6500:<VCF>         NHLBI Exome Sequencing Project population variants
            1000g-phase3:<VCF>    1000 Genomes Project Phase 3 population frequencies
            dbnsfp:<TXT>          dbNSFP functional prediction database

            Example:
                --standard-annotation-resources \ 
                    dbsnp138:dbsnp138.vcf.gz  \ 
                    clinvar:clinvar.vcf.gz

    -t, --threads <INT>
        Number of threads to use (default: 4)

    --min-memory <INT>
        Minimum memory in GB (default: 8)

    --max-memory <INT>
        Maximum memory in GB (default: 16)

    -h, --help
        Show this help message and exit
```

# Dependencies

This tool relies on multiple third-party tools, Python libraries and R libraries

## External tools
- `bwa` -  [GitHub](https://github.com/lh3/bwa) | [Website](https://bio-bwa.sourceforge.net/)
- `samtools` -  [GitHub](https://github.com/samtools/samtools) | [Website](https://www.htslib.org/)
- `bcftools` -  [GitHub](https://github.com/samtools/bcftools) | [Website](https://samtools.github.io/bcftools/bcftools.html)
- `gatk` -  [GitHub](https://github.com/broadinstitute/gatk) | [Website](https://gatk.broadinstitute.org/hc/en-us)
- `snpeff` -  [GitHub](https://github.com/pcingola/SnpEff) | [Website](https://pcingola.github.io/SnpEff/)
- `snpsift` -  [GitHub](https://github.com/pcingola/SnpSift) | [Website](https://pcingola.github.io/SnpEff/)
- `cnvkit` - [GitHub](https://github.com/etal/cnvkit) | [Website](https://cnvkit.readthedocs.io/en/stable/)
- `jq` -  [GitHub](https://github.com/jqlang/jq) | [Website](https://jqlang.org/)
- `yq` -  [GitHub](https://github.com/mikefarah/yq) | [Website](https://mikefarah.gitbook.io/yq)
## Python libraries

- `pandas`
- `xlsxwriter`
- `cyvcf2`

## R libraries

- `ggplot2`

## License

GNU General Public License Version 3, 29 June 2007. See [LICENSE](https://github.com/lakieungocquyet/ngs-pipeline/blob/main/LICENSE) for details.

## Contact

La Kieu Ngoc Quyet <quyetlakn@gmail.com>