FROM ghcr.io/prefix-dev/pixi:latest AS build
RUN pixi global install -e ngs_pipeline_external_tools -c conda-forge -c bioconda \
    fastp=* bwa=* samtools=* gatk4=* bcftools=* snpeff=* snpsift=* t1k=* seqkit=* optitype=* delly=* dicey=* tracy=* cnvkit=* mosdepth=* picard=3.1.1\
    "openjdk>=21" \
    jq=* go-yq=* 

RUN pixi global install -e ngs_pipeline_python -c conda-forge -c bioconda \
    python=* \
    pyyaml=* pandas=* xlsxwriter=* seaborn=* cyvcf2=* ruamel.yaml=*

RUN pixi global install -e ngs_pipeline_r -c conda-forge -c bioconda \
    r-base=* \
    r-ggplot2=* r-scales=* r-gtable=* r-argparse=* 

FROM ubuntu
WORKDIR /opt/ngs-pipeline
COPY --from=build /root/.pixi /root/.pixi 
COPY src /opt/ngs-pipeline/src/
ENV PATH="/opt/ngs-pipeline/:/root/.pixi/bin:$PATH"
RUN chmod +x /opt/ngs-pipeline/src/main.sh
RUN ln -s /opt/ngs-pipeline/src/main.sh /opt/ngs-pipeline/ngs-pipeline