import argparse
import pandas as pd
from cyvcf2 import VCF
import sys
import logging
import time
import xlsxwriter
import pathlib
import sys
import os

def setup_logging(
    logger_name: str,
    log_file_path: str = None
    ):
    logger = logging.getLogger(f"{logger_name}")
    logger.setLevel(logging.INFO)
    
    if logger.hasHandlers():
        logger.handlers.clear()


    COLORS = {
        "DEBUG": "\033[36m",
        "INFO": "\033[32m",
        "WARNING": "\033[33m",
        "ERROR": "\033[31m",
    }
    RESET = "\033[0m"

    def format_log(record, use_color=True):
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(record.created))  # UTC
        level = record.levelname
        message = record.getMessage()

        LEVEL_WIDTH = 9

        raw_block = f"[{level}]"
        level_block = raw_block.ljust(LEVEL_WIDTH)

        if use_color:
            color = COLORS.get(level, "")
            level_colored = f"{color}{level}{RESET}"

            level_block = level_block.replace(level, level_colored)
            timestamp = f"\033[33m{timestamp}\033[0m"

        return f"[{timestamp}] {level_block} {message}"
        

    class SimpleFormatter(logging.Formatter):
        def __init__(self, use_color):
            super().__init__()
            self.use_color = use_color

        def format(self, record):
            return format_log(record, self.use_color)    
        

    # STREAM
    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(SimpleFormatter(use_color=True))
    logger.addHandler(stream_handler)


    # FILE 
    if log_file_path:
        os.makedirs(os.path.dirname(log_file_path), exist_ok=True)
        file_handler = logging.FileHandler(f"{log_file_path}", mode="a", encoding="utf-8")
        file_handler.setFormatter(SimpleFormatter(use_color=False))
        logger.addHandler(file_handler)
    
    return logger

setup_logging(
    logger_name = "logger",
)

GENERAL_INFO =  [
                "CHROM"             ,"POS"               ,"REF"               ,"ALT"               ,"DP"                ,
                "AD"                ,"QUAL"              ,"MQ"                ,"Zygosity"          ,"FILTER"            ,
                "Effect"            ,"Putative_Impact"   ,"Gene_Name"         ,"Feature_Type"      ,"Feature_ID"        ,
                "Transcript_BioType","Rank/Total"        ,"HGVS.c"            ,"HGVS.p"            ,"REF_AA"            ,
                "ALT_AA"            ,"cDNA_pos"          ,"cDNA_length"       ,"CDS_pos"           ,"CDS_length"        ,
                "AA_pos"            ,"AA_length"         ,"Distance"
                ]
DBSNP_INFO =    [
                "dbSNP138_ID"       ,"dbSNP156_ID"
                ]
P3_1000G_INFO = [ 
                "p3_1000G_AF"       ,"p3_1000G_AFR_AF"   ,"p3_1000G_AMR_AF"   ,"p3_1000G_EAS_AF"   ,"p3_1000G_EUR_AF"   ,
                "p3_1000G_SAS_AF"
                ]
ESP6500_INFO =  [
                "ESP6500_MAF_EA"    ,"ESP6500_MAF_AA"    ,"ESP6500_MAF_ALL"
                ]
CLINVAR_INFO =  [
                "CLINVAR_CLNSIG"    ,"CLINVAR_CLNDISDB"  ,"CLINVAR_CLNDN"     ,"CLINVAR_CLNREVSTAT"
                ]

DBNSFP_INFO =   [
                "ACMG_SF_v3.2"                          ,"REF_AA_dbnsfp"                         ,"ALT_AA_dbnsfp"                         ,"hg38_chr"                              ,"hg38_pos(1-based)"                     ,
                "cds_strand"                            ,"refcodon"                              ,"codonpos"                              ,"codon_degeneracy"                      ,"SIFT_score"                            ,
                "SIFT_converted_rankscore"              ,"SIFT_pred"                             ,"LRT_score"                             ,"LRT_converted_rankscore"               ,"LRT_pred"                              ,
                "LRT_Omega"                             ,"MutationTaster_score"                  ,"MutationTaster_converted_rankscore"    ,"MutationTaster_pred"                   ,"MutationTaster_model"                  ,
                "MutationTaster_AAE"                    ,"MutationAssessor_score"                ,"MutationAssessor_rankscore"            ,"MutationAssessor_pred"                 ,"FATHMM_score"                          ,
                "FATHMM_converted_rankscore"            ,"FATHMM_pred"                           ,"PROVEAN_score"                         ,"PROVEAN_converted_rankscore"           ,"PROVEAN_pred"                          ,
                "MetaSVM_score"                         ,"MetaSVM_rankscore"                     ,"MetaSVM_pred"                          ,"MetaLR_score"                          ,"MetaLR_rankscore"                      ,
                "MetaLR_pred"                           ,"Reliability_index"                     ,"M-CAP_score"                           ,"M-CAP_rankscore"                       ,"M-CAP_pred"                            ,
                "MutPred_score"                         ,"MutPred_rankscore"                     ,"MutPred_protID"                        ,"MutPred_AAchange"                      ,"MutPred_Top5features"                  ,
                "fathmm-MKL_coding_score"               ,"fathmm-MKL_coding_rankscore"           ,"fathmm-MKL_coding_pred"                ,"fathmm-MKL_coding_group"               ,"Eigen-raw_coding"                      ,
                "Eigen-phred_coding"                    ,"Eigen-PC-raw_coding"                   ,"Eigen-PC-phred_coding"                 ,"Eigen-PC-raw_coding_rankscore"         ,"integrated_fitCons_score"              ,
                "integrated_fitCons_rankscore"          ,"integrated_confidence_value"           ,"GERP++_NR"                             ,"GERP++_RS"                             ,"GERP++_RS_rankscore"                   ,
                "gnomAD_exomes_AC"                      ,"gnomAD_exomes_AN"                      ,"gnomAD_exomes_AF"                      ,"gnomAD_exomes_AFR_AC"                  ,"gnomAD_exomes_AFR_AN"                  ,
                "gnomAD_exomes_AFR_AF"                  ,"gnomAD_exomes_AMR_AC"                  ,"gnomAD_exomes_AMR_AN"                  ,"gnomAD_exomes_AMR_AF"                  ,"gnomAD_exomes_ASJ_AC"                  ,
                "gnomAD_exomes_ASJ_AN"                  ,"gnomAD_exomes_ASJ_AF"                  ,"gnomAD_exomes_EAS_AC"                  ,"gnomAD_exomes_EAS_AN"                  ,"gnomAD_exomes_EAS_AF"                  ,
                "gnomAD_exomes_FIN_AC"                  ,"gnomAD_exomes_FIN_AN"                  ,"gnomAD_exomes_FIN_AF"                  ,"gnomAD_exomes_NFE_AC"                  ,"gnomAD_exomes_NFE_AN"                  ,
                "gnomAD_exomes_NFE_AF"                  ,"gnomAD_exomes_SAS_AC"                  ,"gnomAD_exomes_SAS_AN"                  ,"gnomAD_exomes_SAS_AF"                  ,"gnomAD_genomes_AC"                     ,
                "gnomAD_genomes_AN"                     ,"gnomAD_genomes_AF"                     ,"gnomAD_genomes_AFR_AC"                 ,"gnomAD_genomes_AFR_AN"                 ,"gnomAD_genomes_AFR_AF"                 ,
                "gnomAD_genomes_AMR_AC"                 ,"gnomAD_genomes_AMR_AN"                 ,"gnomAD_genomes_AMR_AF"                 ,"gnomAD_genomes_ASJ_AC"                 ,"gnomAD_genomes_ASJ_AN"                 ,
                "gnomAD_genomes_ASJ_AF"                 ,"gnomAD_genomes_EAS_AC"                 ,"gnomAD_genomes_EAS_AN"                 ,"gnomAD_genomes_EAS_AF"                 ,"gnomAD_genomes_FIN_AC"                 ,
                "gnomAD_genomes_FIN_AN"                 ,"gnomAD_genomes_FIN_AF"                 ,"gnomAD_genomes_NFE_AC"                 ,"gnomAD_genomes_NFE_AN"                 ,"gnomAD_genomes_NFE_AF"                 ,
                "Interpro_domain"                       ,"GTEx_V8_gene"                          ,"GTEx_V8_tissue"                        ,"MIM_id"
                ]
OTHERS =        [
                "Gene_old_names","Gene_full_name","Pathway(Uniprot)","Pathway(BioCarta)_short","Pathway(BioCarta)_full","Pathway(ConsensusPathDB)",
                "Pathway(KEGG)_id","Pathway(KEGG)_full","Function_description","Disease_description","MIM_phenotype_id","MIM_disease","Trait_association(GWAS)",
                "GO_biological_process","GO_cellular_component","GO_molecular_function","Tissue_specificity(Uniprot)","Expression(egenetics)","Expression(GNF/Atlas)",
                "Interactions(IntAct)","Interactions(BioGRID)","Interactions(ConsensusPathDB)","P(HI)","P(rec)","Known_rec_info","RVIS_EVS","RVIS_percentile_EVS",
                "LoF-FDR_ExAC","RVIS_ExAC","RVIS_percentile_ExAC","GHIS","GDI","GDI-Phred","Gene_damage_prediction(all_disease-causing_genes)",
                "Gene_damage_prediction(all_Mendelian_disease-causing_genes)","Gene_damage_prediction(Mendelian_AD_disease-causing_genes)",
                "Gene_damage_prediction(Mendelian_AR_disease-causing_genes)","Gene_damage_prediction(all_PID_disease-causing_genes)",
                "Gene_damage_prediction(PID_AD_disease-causing_genes)","Gene_damage_prediction(PID_AR_disease-causing_genes)",
                "Gene_damage_prediction(all_cancer_disease-causing_genes)","Gene_damage_prediction(cancer_recessive_disease-causing_genes)",
                "Gene_damage_prediction(cancer_dominant_disease-causing_genes)"
            ]

logger = logging.getLogger("logger")

parser = argparse.ArgumentParser(
        description = "None"
    )
parser.add_argument(
        "-I", "--input",
        required = True, 
        type = str, 
        help = "None"
    )

parser.add_argument(
        "-O", "--output",
        required = True, 
        type = str, 
        help = "None"
    )
arguments = parser.parse_args()

input_file_path = arguments.input
output_file_path = arguments.output

VCF_FILE = VCF(f"{input_file_path}")
data = []
HEADER = GENERAL_INFO + DBSNP_INFO + P3_1000G_INFO + ESP6500_INFO + CLINVAR_INFO + DBNSFP_INFO

TOTAL_RECORD = sum(1 for _ in VCF(f"{input_file_path}"))
logger.info(f"Total variant: {TOTAL_RECORD:,}")
for record in VCF_FILE:
    ANN_values = record.INFO.get("ANN")
    if not ANN_values:
        continue
    if isinstance(ANN_values, str):
        ANN_values_first = ANN_values.split(",")[0]
    else:
        ANN_values_first = ANN_values[0]
    ANN_field_value =  ANN_values_first.split("|")    

    row = {}
    # ==================================================================================================== #
    #                                           General fields
    # ==================================================================================================== #
    row["CHROM"] = record.CHROM
    row["POS"] = record.POS
    row["REF"] = record.REF
    row["ALT"] = record.ALT[0] if record.ALT else None
    dp_array = record.format("DP", None)
    row["DP"] = int(dp_array[0][0]) if dp_array is not None else None
    ad_array = record.format("AD")
    row["AD"] = int(ad_array[0][1]) if ad_array is not None and len(ad_array[0]) > 1 else None
    row["QUAL"] = round(record.QUAL,2) 
    row["MQ"] = round(record.INFO.get("MQ", None),2) 
    gt = record.genotypes[0] 
    if gt[0] == gt[1]:
        row["Zygosity"] = "HOM" if gt[0] != 0 else "Ref"
    else:
        row["Zygosity"] = "HET"
    row["FILTER"] = record.FILTER if record.FILTER else "PASS"
    row["Effect"] = ANN_field_value[1] if len(ANN_field_value) > 1 else None
    row["Putative_Impact"] = ANN_field_value[2] if len(ANN_field_value) > 2 else None
    row["Gene_Name"] = ANN_field_value[3] if len(ANN_field_value) > 3 else None
    row["Feature_Type"] = ANN_field_value[5] if len(ANN_field_value) > 5 else None
    row["Feature_ID"] = ANN_field_value[6] if len(ANN_field_value) > 6 else None
    row["Transcript_BioType"] = ANN_field_value[7] if len(ANN_field_value) > 7 else None
    row["Rank/Total"] = ANN_field_value[8] if len(ANN_field_value) > 8 else None
    row["HGVS.c"] = ANN_field_value[9] if len(ANN_field_value) > 9 else None
    row["HGVS.p"] = ANN_field_value[10] if len(ANN_field_value) > 10 else None
    if len(ANN_field_value) > 11:
        cDNA = ANN_field_value[11].split("/") if "/" in ANN_field_value[11] else [ANN_field_value[11], None]
        row["cDNA_pos"] = cDNA[0]
        row["cDNA_length"] = cDNA[1]
    if len(ANN_field_value) > 12:
        CDS = ANN_field_value[12].split("/") if "/" in ANN_field_value[12] else [ANN_field_value[12], None]
        row["CDS_pos"] = CDS[0]
        row["CDS_length"] = CDS[1]
    if len(ANN_field_value) > 13:
        AA = ANN_field_value[13].split("/") if "/" in ANN_field_value[13] else [ANN_field_value[13], None]
        row["AA_pos"] = AA[0]
        row["AA_length"] = AA[1]
    row["Distance"] = ANN_field_value[14] if len(ANN_field_value) > 14 else None
    # ==================================================================================================== #
    #                                       dbSNP138 annotation
    # ==================================================================================================== #
    row["dbSNP138_ID"] = record.ID
    # ==================================================================================================== #
    #                                   1000 genomes phase 3 annotation
    # ==================================================================================================== #
    row["p3_1000G_AF"] = record.INFO.get("p3_1000G_AF", None)
    row["p3_1000G_AFR_AF"] = record.INFO.get("p3_1000G_AFR_AF", None)
    row["p3_1000G_AMR_AF"] = record.INFO.get("p3_1000G_AMR_AF", None)
    row["p3_1000G_EAS_AF"] = record.INFO.get("p3_1000G_EAS_AF", None)
    row["p3_1000G_EUR_AF"] = record.INFO.get("p3_1000G_EUR_AF", None)
    row["p3_1000G_SAS_AF"] = record.INFO.get("p3_1000G_SAS_AF", None)
    # ==================================================================================================== #
    #                                           ESP6500 annotation
    # ==================================================================================================== #
    ESP6500_MAF_str = record.INFO.get("ESP6500_MAF", None)
    if ESP6500_MAF_str:
        ESP6500_MAF_array = ESP6500_MAF_str.split(",")
        EA = float(ESP6500_MAF_array[0]) / 100 if ESP6500_MAF_array[0] not in (".", "") else None
        AA = float(ESP6500_MAF_array[1]) / 100 if ESP6500_MAF_array[1] not in (".", "") else None
        ALL = float(ESP6500_MAF_array[2]) / 100 if ESP6500_MAF_array[2] not in (".", "") else None
    else:
        EA = AA = ALL = None
    row["ESP6500_MAF_EA"] = EA
    row["ESP6500_MAF_AA"] = AA
    row["ESP6500_MAF_ALL"] = ALL
    # ==================================================================================================== #
    #                                          Clinvar annotation
    # ==================================================================================================== #
    row["CLINVAR_CLNSIG"] = record.INFO.get("CLINVAR_CLNSIG", None)
    row["CLINVAR_CLNDISDB"] = record.INFO.get("CLINVAR_CLNDISDB", None)
    row["CLINVAR_CLNDN"] = record.INFO.get("CLINVAR_CLNDN", None)
    row["CLINVAR_CLNREVSTAT"] = record.INFO.get("CLINVAR_CLNREVSTAT", None)
    # ==================================================================================================== #
    #                                           dbNSFP annotation
    # ==================================================================================================== #
    row["REF_AA_dbnsfp"] = record.INFO.get("dbNSFP_aaref", None)
    row["ALT_AA_dbnsfp"] = record.INFO.get("dbNSFP_aaalt", None)
    row["hg38_chr"] = record.INFO.get("dbNSFP_hg38_chr", None)
    row["hg38_pos(1-based)"] = record.INFO.get("dbNSFP_hg38_pos_1_based_", None)
    row["cds_strand"] = record.INFO.get("dbNSFP_cds_strand", None)
    row["refcodon"] = record.INFO.get("dbNSFP_refcodon", None)
    row["codonpos"] = record.INFO.get("dbNSFP_codonpos", None)
    row["codon_degeneracy"] = record.INFO.get("dbNSFP_codon_degeneracy", None)
    row["SIFT_score"] = record.INFO.get("dbNSFP_SIFT_score", None)
    row["SIFT_converted_rankscore"] = record.INFO.get("dbNSFP_SIFT_converted_rankscore", None)
    row["SIFT_pred"] = record.INFO.get("dbNSFP_SIFT_pred", None)
    row["LRT_score"] = record.INFO.get("dbNSFP_LRT_score", None)
    row["LRT_converted_rankscore"] = record.INFO.get("dbNSFP_LRT_converted_rankscore", None)
    row["LRT_pred"] = record.INFO.get("dbNSFP_LRT_pred", None)
    row["LRT_Omega"] = record.INFO.get("dbNSFP_LRT_Omega", None)
    row["MutationTaster_score"] = record.INFO.get("dbNSFP_MutationTaster_score", None)
    row["MutationTaster_converted_rankscore"] = record.INFO.get("dbNSFP_MutationTaster_converted_rankscore", None)
    row["MutationTaster_pred"] = record.INFO.get("dbNSFP_MutationTaster_pred", None)
    row["MutationTaster_model"] = record.INFO.get("dbNSFP_MutationTaster_model", None)
    row["MutationTaster_AAE"] = record.INFO.get("dbNSFP_MutationTaster_AAE", None)
    row["MutationAssessor_score"] = record.INFO.get("dbNSFP_MutationAssessor_score", None)
    row["MutationAssessor_rankscore"] = record.INFO.get("dbNSFP_MutationAssessor_rankscore", None)
    row["MutationAssessor_pred"] = record.INFO.get("dbNSFP_MutationAssessor_pred", None)
    row["FATHMM_score"] = record.INFO.get("dbNSFP_FATHMM_score", None)
    row["FATHMM_converted_rankscore"] = record.INFO.get("dbNSFP_FATHMM_converted_rankscore", None)
    row["FATHMM_pred"] = record.INFO.get("dbNSFP_FATHMM_pred", None)
    row["PROVEAN_score"] = record.INFO.get("dbNSFP_PROVEAN_score", None)
    row["PROVEAN_converted_rankscore"] = record.INFO.get("dbNSFP_PROVEAN_converted_rankscore", None)
    row["PROVEAN_pred"] = record.INFO.get("dbNSFP_PROVEAN_pred", None)
    row["MetaSVM_score"] = record.INFO.get("dbNSFP_MetaSVM_score", None)
    row["MetaSVM_rankscore"] = record.INFO.get("dbNSFP_MetaSVM_rankscore", None)
    row["MetaSVM_pred"] = record.INFO.get("dbNSFP_MetaSVM_pred", None)
    row["MetaLR_score"] = record.INFO.get("dbNSFP_MetaLR_score", None)
    row["MetaLR_rankscore"] = record.INFO.get("dbNSFP_MetaLR_rankscore", None)
    row["MetaLR_pred"] = record.INFO.get("dbNSFP_MetaLR_pred", None)
    row["Reliability_index"] = record.INFO.get("dbNSFP_Reliability_index", None)
    row["M-CAP_score"] = record.INFO.get("dbNSFP_M_CAP_score", None)
    row["M-CAP_rankscore"] = record.INFO.get("dbNSFP_M_CAP_rankscore", None)
    row["M-CAP_pred"] = record.INFO.get("dbNSFP_M_CAP_pred", None)
    row["MutPred_score"] = record.INFO.get("dbNSFP_MutPred_score", None)
    row["MutPred_rankscore"] = record.INFO.get("dbNSFP_MutPred_rankscore", None)
    row["MutPred_protID"] = record.INFO.get("dbNSFP_MutPred_protID", None)
    row["MutPred_AAchange"] = record.INFO.get("dbNSFP_MutPred_AAchange", None)
    row["MutPred_Top5features"] = record.INFO.get("dbNSFP_MutPred_Top5features", None)
    row["fathmm-MKL_coding_score"] = record.INFO.get("dbNSFP_fathmm_MKL_coding_score", None)
    row["fathmm-MKL_coding_rankscore"] = record.INFO.get("dbNSFP_fathmm_MKL_coding_rankscore", None)
    row["fathmm-MKL_coding_pred"] = record.INFO.get("dbNSFP_fathmm_MKL_coding_pred", None)
    row["fathmm-MKL_coding_group"] = record.INFO.get("dbNSFP_fathmm_MKL_coding_group", None)
    row["Eigen-raw_coding"] = record.INFO.get("dbNSFP_Eigen_raw_coding", None)
    row["Eigen-phred_coding"] = record.INFO.get("dbNSFP_Eigen_phred_coding", None)
    row["Eigen-PC-raw_coding"] = record.INFO.get("dbNSFP_Eigen_PC_raw_coding", None)
    row["Eigen-PC-phred_coding"] = record.INFO.get("dbNSFP_Eigen_PC_phred_coding", None)
    row["Eigen-PC-raw_coding_rankscore"] = record.INFO.get("dbNSFP_Eigen_PC_raw_coding_rankscore", None)
    row["integrated_fitCons_score"] = record.INFO.get("dbNSFP_integrated_fitCons_score", None)
    row["integrated_fitCons_rankscore"] = record.INFO.get("dbNSFP_integrated_fitCons_rankscore", None)
    row["integrated_confidence_value"] = record.INFO.get("dbNSFP_integrated_confidence_value", None)
    row["GERP++_NR"] = record.INFO.get("dbNSFP_GERP___NR", None)
    row["GERP++_RS"] = record.INFO.get("dbNSFP_GERP___RS", None)
    row["GERP++_RS_rankscore"] = record.INFO.get("dbNSFP_GERP___RS_rankscore", None)
    row["gnomAD_exomes_AC"] = record.INFO.get("dbNSFP_gnomAD_exomes_AC", None)
    row["gnomAD_exomes_AN"] = record.INFO.get("dbNSFP_gnomAD_exomes_AN", None)
    row["gnomAD_exomes_AF"] = record.INFO.get("dbNSFP_gnomAD_exomes_AF", None)
    row["gnomAD_exomes_AFR_AC"] = record.INFO.get("dbNSFP_gnomAD_exomes_AFR_AC", None)
    row["gnomAD_exomes_AFR_AN"] = record.INFO.get("dbNSFP_gnomAD_exomes_AFR_AN", None)
    row["gnomAD_exomes_AFR_AF"] = record.INFO.get("dbNSFP_gnomAD_exomes_AFR_AF", None)
    row["gnomAD_exomes_AMR_AC"] = record.INFO.get("dbNSFP_gnomAD_exomes_AMR_AC", None)
    row["gnomAD_exomes_AMR_AN"] = record.INFO.get("dbNSFP_gnomAD_exomes_AMR_AN", None)
    row["gnomAD_exomes_AMR_AF"] = record.INFO.get("dbNSFP_gnomAD_exomes_AMR_AF", None)
    row["gnomAD_exomes_ASJ_AC"] = record.INFO.get("dbNSFP_gnomAD_exomes_ASJ_AC", None)
    row["gnomAD_exomes_ASJ_AN"] = record.INFO.get("dbNSFP_gnomAD_exomes_ASJ_AN", None)
    row["gnomAD_exomes_ASJ_AF"] = record.INFO.get("dbNSFP_gnomAD_exomes_ASJ_AF", None)
    row["gnomAD_exomes_EAS_AC"] = record.INFO.get("dbNSFP_gnomAD_exomes_EAS_AC", None)
    row["gnomAD_exomes_EAS_AN"] = record.INFO.get("dbNSFP_gnomAD_exomes_EAS_AN", None)
    row["gnomAD_exomes_EAS_AF"] = record.INFO.get("dbNSFP_gnomAD_exomes_EAS_AF", None)
    row["gnomAD_exomes_FIN_AC"] = record.INFO.get("dbNSFP_gnomAD_exomes_FIN_AC", None)
    row["gnomAD_exomes_FIN_AN"] = record.INFO.get("dbNSFP_gnomAD_exomes_FIN_AN", None)
    row["gnomAD_exomes_FIN_AF"] = record.INFO.get("dbNSFP_gnomAD_exomes_FIN_AF", None)
    row["gnomAD_exomes_NFE_AC"] = record.INFO.get("dbNSFP_gnomAD_exomes_NFE_AC", None)
    row["gnomAD_exomes_NFE_AN"] = record.INFO.get("dbNSFP_gnomAD_exomes_NFE_AN", None)
    row["gnomAD_exomes_NFE_AF"] = record.INFO.get("dbNSFP_gnomAD_exomes_NFE_AF", None)
    row["gnomAD_exomes_SAS_AC"] = record.INFO.get("dbNSFP_gnomAD_exomes_SAS_AC", None)
    row["gnomAD_exomes_SAS_AN"] = record.INFO.get("dbNSFP_gnomAD_exomes_SAS_AN", None)
    row["gnomAD_exomes_SAS_AF"] = record.INFO.get("dbNSFP_gnomAD_exomes_SAS_AF", None)
    row["gnomAD_genomes_AC"] = record.INFO.get("dbNSFP_gnomAD_genomes_AC", None)
    row["gnomAD_genomes_AN"] = record.INFO.get("dbNSFP_gnomAD_genomes_AN", None)
    row["gnomAD_genomes_AF"] = record.INFO.get("dbNSFP_gnomAD_genomes_AF", None)
    row["gnomAD_genomes_AFR_AC"] = record.INFO.get("dbNSFP_gnomAD_genomes_AFR_AC", None)
    row["gnomAD_genomes_AFR_AN"] = record.INFO.get("dbNSFP_gnomAD_genomes_AFR_AN", None)
    row["gnomAD_genomes_AFR_AF"] = record.INFO.get("dbNSFP_gnomAD_genomes_AFR_AF", None)
    row["gnomAD_genomes_AMR_AC"] = record.INFO.get("dbNSFP_gnomAD_genomes_AMR_AC", None)
    row["gnomAD_genomes_AMR_AN"] = record.INFO.get("dbNSFP_gnomAD_genomes_AMR_AN", None)
    row["gnomAD_genomes_AMR_AF"] = record.INFO.get("dbNSFP_gnomAD_genomes_AMR_AF", None)
    row["gnomAD_genomes_ASJ_AC"] = record.INFO.get("dbNSFP_gnomAD_genomes_ASJ_AC", None)
    row["gnomAD_genomes_ASJ_AN"] = record.INFO.get("dbNSFP_gnomAD_genomes_ASJ_AN", None)
    row["gnomAD_genomes_ASJ_AF"] = record.INFO.get("dbNSFP_gnomAD_genomes_ASJ_AF", None)
    row["gnomAD_genomes_EAS_AC"] = record.INFO.get("dbNSFP_gnomAD_genomes_EAS_AC", None)
    row["gnomAD_genomes_EAS_AN"] = record.INFO.get("dbNSFP_gnomAD_genomes_EAS_AN", None)
    row["gnomAD_genomes_EAS_AF"] = record.INFO.get("dbNSFP_gnomAD_genomes_EAS_AF", None)
    row["gnomAD_genomes_FIN_AC"] = record.INFO.get("dbNSFP_gnomAD_genomes_FIN_AC", None)
    row["gnomAD_genomes_FIN_AN"] = record.INFO.get("dbNSFP_gnomAD_genomes_FIN_AN", None)
    row["gnomAD_genomes_FIN_AF"] = record.INFO.get("dbNSFP_gnomAD_genomes_FIN_AF", None)
    row["gnomAD_genomes_NFE_AC"] = record.INFO.get("dbNSFP_gnomAD_genomes_NFE_AC", None)
    row["gnomAD_genomes_NFE_AN"] = record.INFO.get("dbNSFP_gnomAD_genomes_NFE_AN", None)
    row["gnomAD_genomes_NFE_AF"] = record.INFO.get("dbNSFP_gnomAD_genomes_NFE_AF", None)
    row["Interpro_domain"] = record.INFO.get("dbNSFP_Interpro_domain", None)
    row["GTEx_V8_gene"] = record.INFO.get("dbNSFP_GTEx_V8_gene", None)
    row["GTEx_V8_tissue"] = record.INFO.get("dbNSFP_GTEx_V8_tissue", None)
    row["MIM_id"] = record.INFO.get("dbNSFP_clinvar_OMIM_id", None)

    # row["Gene_old_names"] = record.INFO.get("", None)
    # row["Gene_full_name"] = record.INFO.get("", None)
    # row["Pathway(Uniprot)"] = record.INFO.get("", None)
    # row["Pathway(BioCarta)_short"] = record.INFO.get("", None)
    # row["Pathway(BioCarta)_full"] = record.INFO.get("", None)
    # row["Pathway(ConsensusPathDB)"] = record.INFO.get("", None)
    # row["Pathway(KEGG)_id"] = record.INFO.get("", None)
    # row["Pathway(KEGG)_full"] = record.INFO.get("", None)
    # row["Function_description"] = record.INFO.get("", None)
    # row["Disease_description"] = record.INFO.get("", None)
    # row["MIM_phenotype_id"] = record.INFO.get("", None)
    # row["MIM_disease"] = record.INFO.get("", None)
    # row["Trait_association(GWAS)"] = record.INFO.get("", None)
    # row["GO_biological_process"] = record.INFO.get("", None)
    # row["GO_cellular_component"] = record.INFO.get("", None)
    # row["GO_molecular_function"] = record.INFO.get("", None)
    # row["Tissue_specificity(Uniprot)"] = record.INFO.get("", None)
    # row["Expression(egenetics)"] = record.INFO.get("", None)
    # row["Expression(GNF/Atlas)"] = record.INFO.get("", None)
    # row["Interactions(IntAct)"] = record.INFO.get("", None)
    # row["Interactions(BioGRID)"] = record.INFO.get("", None)
    # row["Interactions(ConsensusPathDB)"] = record.INFO.get("", None)
    # row["P(HI)"] = record.INFO.get("", None)
    # row["P(rec)"] = record.INFO.get("", None)
    # row["Known_rec_info"] = record.INFO.get("", None)
    # row["RVIS_EVS"] = record.INFO.get("", None)
    # row["RVIS_percentile_EVS"] = record.INFO.get("", None)
    # row["LoF-FDR_ExAC"] = record.INFO.get("", None)
    # row["RVIS_ExAC"] = record.INFO.get("", None)
    # row["RVIS_percentile_ExAC"] = record.INFO.get("", None)
    # row["GHIS"] = record.INFO.get("", None)
    # row["GDI"] = record.INFO.get("", None)
    # row["GDI-Phred"] = record.INFO.get("", None)
    # row["Gene_damage_prediction(all_disease-causing_genes)"] = record.INFO.get("", None)
    # row["Gene_damage_prediction(all_Mendelian_disease-causing_genes)"] = record.INFO.get("", None)
    # row["Gene_damage_prediction(Mendelian_AD_disease-causing_genes)"] = record.INFO.get("", None)
    # row["Gene_damage_prediction(Mendelian_AR_disease-causing_genes)"] = record.INFO.get("", None)
    # row["Gene_damage_prediction(all_PID_disease-causing_genes)"] = record.INFO.get("", None)
    # row["Gene_damage_prediction(PID_AD_disease-causing_genes)"] = record.INFO.get("", None)
    # row["Gene_damage_prediction(PID_AR_disease-causing_genes)"] = record.INFO.get("", None)
    # row["Gene_damage_prediction(all_cancer_disease-causing_genes)"] = record.INFO.get("", None)
    # row["Gene_damage_prediction(cancer_recessive_disease-causing_genes)"] = record.INFO.get("", None)
    # row["Gene_damage_prediction(cancer_dominant_disease-causing_genes)"] = record.INFO.get("", None)
    
    data.append(row)

data_frame = pd.DataFrame(data, columns=HEADER)
with pd.ExcelWriter(f"{output_file_path}", engine="xlsxwriter") as writer:
    data_frame_filled = data_frame.fillna(".")
    data_frame_filled.to_excel(writer, index=False, sheet_name="Sheet 1")
    workbook = writer.book
    worksheet = writer.sheets["Sheet 1"]

    header_format = workbook.add_format({
        'bold': True,
        'font_color': 'black',
        'font_size': 9,  
        'bg_color': "#ADCAE6",
        'border': 1,
        'font_name': 'Arial',
        'align': 'center',
        'valign': 'vcenter',
        'text_wrap': True,
    })
    data_format = workbook.add_format({
        'font_name': 'Arial',
        'font_color': 'black',
        'font_size': 9,  
        'bold': False,
        'text_wrap': False, 
        'align': 'general' 
    })
    # Add header format
    for col_num, value in enumerate(data_frame.columns.values):
        worksheet.write(0, col_num, value, header_format)

    # Set filter for the header row
    worksheet.autofilter(0, 0, 0, len(data_frame.columns)-1)

    row_height = 7 * 15
    worksheet.set_row(0, row_height)

    for row_num in range(1, len(data_frame_filled) + 1):
        worksheet.set_row(row_num, 15.5, data_format)                    
