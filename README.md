# Overview
Workflow for NGS data analysis

This repository contains source code. The contents of this repository are 100% open source and released under the GPL-3.0 license (see [LICENSE.TXT](https://github.com/lakieungocquyet/ngs-pipeline/blob/main/LICENSE)).


# Requirements
*   Unix-like operating system (cannot run on Windows)

# Installation

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

<!-- # How to use
### 1. Prepare input data
Prepare your Whole Exome Sequencing (WES) raw data (typically FASTQ files). 

Example:

```
home/
└──user/
    └──input/
        ├── sample1/
        │   ├── sample1.R1.fastq.gz
        │   └── sample1.R2.fastq.gz
        └── sample2/
            ├── sample2.R1.fastq.gz
            └── sample2.R2.fastq.gz
```
### 2. Configure input parameters (YAML)

Forge uses a YAML configuration file to define inputs, outputs.

Example: run.yaml
```
# Please don't use tab characters for indentation in this file. Use spaces only.
sample: [
  { 
    id: NF2_01, 
    platform: "illumina", 
    read1: /home/lknq/WES_samples/NF2_01/NF2_01_1.trim.fastq.gz,
    read2: /home/lknq/WES_samples/NF2_01/NF2_01_2.trim.fastq.gz
  },
  { 
    id: RGNC07, 
    platform: "illumina", 
    read1: /home/lknq/WES_samples/RGNC07/RGNC07_1.trim.fastq.gz,
    read2: /home/lknq/WES_samples/RGNC07/RGNC07_2.trim.fastq.gz
  },
  # You can add more samples as needed
  # { 
  #   id: , 
  #   platform: , # platform: (illumina/nanopore/pacbio)
  #   read1: ,
  #   read2: 
  # },
]
```
#### Configuration details

The YAML configuration file includes:

- `sample`: list of samples with metadata and file paths  

Fields:

- `id`: unique sample identifier  
- `platform`: sequencing platform (e.g., illumina)  
- `read1`, `read2`: paths to paired-end FASTQ files  
### 3. Run the variant calling pipeline

Example:

```
forge callvariants \
    -I ~/GitHub/forge/example/input.yaml \
    -O ~/GitHub/forge/results \
    -R ~/GitHub/forge/resources/hg19/reference_genome_hg19/hg19.p13.plusMT.no_alt_analysis_set.fa \
    -r ~/GitHub/forge/resources/hg19/regions_hg19/s07604624_hg19/s07604624_covered.bed \
    --bqsr-known-sites \
        ~/GitHub/forge/resources/hg19/variant_resources_hg19/1000g_phase1_indels_hg19/1000G_phase1.indels.hg19.sites.vcf.bgz \
        ~/GitHub/forge/resources/hg19/variant_resources_hg19/dbsnp_138_hg19/dbsnp_138.hg19.vcf.bgz \
        ~/GitHub/forge/resources/hg19/variant_resources_hg19/1000g_omni2_5_hg19/1000G_omni2.5.hg19.sites.vcf.bgz \
    --annotation-resource \
        dbsnp_138=~/GitHub/forge/resources/hg19/variant_resources_hg19/dbsnp_138_hg19/dbsnp_138.hg19.vcf.bgz \
        phase1_1000g_indels=~/GitHub/forge/resources/hg19/variant_resources_hg19/1000g_phase1_indels_hg19/1000G_phase1.indels.hg19.sites.vcf.bgz \
        omni2_5_1000g=~/GitHub/forge/resources/hg19/variant_resources_hg19/1000g_omni2_5_hg19/1000G_omni2.5.hg19.sites.vcf.bgz \
    --annotation-resource \
        clinvar=~/GitHub/forge/resources/hg19/variant_resources_hg19/clinvar_20240716_hg19/clinvar_20240716.hg19.vcf.bgz \
        dbnsfp=~/GitHub/forge/resources/hg19/variant_resources_hg19/dbnsfp4_9a_hg19/dbnsfp4.9a_hg19.txt.bgz \
        esp6500si_v2_ssa137=~/GitHub/forge/resources/hg19/variant_resources_hg19/esp6500si_v2_ssa137_hg19/esp6500si_v2_ssa137.hg19.vcf.bgz \
        phase3_1000g_v4_20130502=~/GitHub/forge/resources/hg19/variant_resources_hg19/1000g_phase3_v4_20130502_sites_hg19/1000G_phase3_v4_20130502.sites.hg19.vcf.bgz \
    -t 8 \
    --min-memory 8 \
    --max-memory 20
``` -->
# Commands

`ngs_pipeline` provides commands for analyzing sequencing data. You can access help from the command line with the `--help` flag:

```
ngs_pipeline --help
```

## `ngs_pipeline`

| Command | Description |
|---------|-------------|
| `call-variants` | Run variant calling pipeline |
| `--help` | Show help message for `ngs_pipeline` and exit |

* `ngs_pipeline call-variants`

```
About: Run variant calling pipeline
Usage:

       forge call-variants [arguments]

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

    --standard-annotation-resources <resource_name>:<file_path> [<resource_name>:<file_path> ...]
        One or more annotation resource databases, each given as <resource_name>:<file_path>, separated by a space.

        Only the following <resource_name>:<file_path> values are accepted:

            dbsnp138:<VCF>        dbSNP build 138 variant database
            clinvar:<VCF>         ClinVar clinical significance annotations
            esp6500:<VCF>         NHLBI Exome Sequencing Project population variants
            1000g-phase3:<VCF>    1000 Genomes Project Phase 3 population frequencies
            dbnsfp:<TXT>          dbNSFP functional prediction database

            Example:
                --standard-annotation-resource \ 
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

<!-- * `forge identify-hla-alleles`
```
About: Run HLA typing pipeline
Usage:

       forge identify-hla-alleles [arguments]

Arguments:

  Required arguments:
    -I, --input <YAML>  Path to the YAML configuration file (e.g., run.yaml)
    -O, --output <DIR>  Path to the directory where results will be stored (e.g., ~/result/)

  Others:
    -h, --help          Show this help message and exit
``` -->

# Dependencies

This tool relies on multiple third-party tools, Python libraries and R libraries

## External tools
- `bwa` -  [Github](https://github.com/lh3/bwa) | [Website](https://bio-bwa.sourceforge.net/)
- `samtools` -  [Github](https://github.com/samtools/samtools) | [Website](https://www.htslib.org/)
- `bcftools` -  [Github](https://github.com/samtools/bcftools) | [Website](https://samtools.github.io/bcftools/bcftools.html)
- `gatk` -  [Github](https://github.com/broadinstitute/gatk) | [Website](https://gatk.broadinstitute.org/hc/en-us)
- `snpeff` -  [Github](https://github.com/pcingola/SnpEff) | [Website](https://pcingola.github.io/SnpEff/)
- `snpsift` -  [Github](https://github.com/pcingola/SnpSift) | [Website](https://pcingola.github.io/SnpEff/)
- `t1k` -  [Github](https://github.com/mourisl/T1K) 

- `jq` -  [Github](https://github.com/jqlang/jq) | [Website](https://jqlang.org/)
## Python libraries

- `pyyaml`
- `pandas`
- `xlsxwriter`
- `seaborn`
- `cyvcf2`

## R libraries

- `ggplot2`

## License

GNU General Public License Version 3, 29 June 2007. See [LICENSE](https://github.com/lakieungocquyet/ngs-pipeline/blob/main/LICENSE) for details.

## Contact

La Kieu Ngoc Quyet <quyetlakn@gmail.com>