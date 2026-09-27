SCRIPT_DIR_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pixi global install -e ngs_pipeline_tools -c conda-forge -c bioconda \
    fastp=* bwa=* samtools=* gatk4=* bcftools=* snpeff=* snpsift=* t1k=* seqkit=* optitype=* delly=* dicey=* tracy=* cnvkit=* mosdepth=* picard=3.1.1\
    "openjdk>=21" \
    jq=* go-yq=* 
    
pixi global install -e ngs_pipeline_python -c conda-forge -c bioconda \
    python=* \
    pyyaml=* pandas=* xlsxwriter=* seaborn=* cyvcf2=* ruamel.yaml=*

pixi global install -e ngs_pipeline_r -c conda-forge -c bioconda \
    r-base=* \
    r-cowplot=* \
    jupyterlab=* \
    r-ggforce=*

Rscript -e '
    if (!require("BiocManager", quietly = TRUE))
        install.packages("BiocManager", repos="https://cloud.r-project.org")
    BiocManager::install("DNAcopy")
'
Rscript -e 'install.packages(c("ggplot2","scales","gtable","argparse"), repos="https://cloud.r-project.org")'

echo "# >>> added by NGS pipeline installer >>>" >> ~/.bashrc
echo "export PATH=\"$SCRIPT_DIR_PATH:\$PATH\"" >> ~/.bashrc
echo "# <<< added by NGS pipeline installer <<<" >> ~/.bashrc

chmod +x "$SCRIPT_DIR_PATH/src/main.sh"
ln -s "$SCRIPT_DIR_PATH/src/main.sh" "$SCRIPT_DIR_PATH/ngs_pipeline"
source ~/.bashrc