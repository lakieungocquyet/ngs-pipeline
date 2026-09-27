set -Eeuo pipefail
SCRIPT_DIR_PATH="$(dirname "$(realpath $0)")"

# logging (Can be a noun (the system/activity) or a verb (the action happening right now)): The overall process or act of recording information about a program's execution.
# logger (Always a noun (the object or tool)): The object or "tool" within your code that captures events and passes them to a destination (like a file or console).
# log (Can be a noun (the record) or a verb (the act of recording): The actual record or entry (the data itself) that is produced, often stored in a "log file. 

#====================================================================================================#
#                         Standardize log messages for a professional style                          #
#====================================================================================================#

# ------------------------- Vietnamese -------------------------
# Chuẩn hóa log message theo phong cách chuyên nghiệp
# Style guide áp dụng
# 1.Thì: dùng present continuous (Verb-ing ...) cho hành động đang thực hiện, past tense cho việc đã hoàn tất, tránh trộn lẫn imperative ("Combine", "Filter"...) như hiện tại.
# 2.Viết hoa đầu câu, không viết hoa tùy tiện giữa câu.
# 3.Không dùng dấu ... thay bằng cách diễn đạt rõ ràng.
# 4.Nhất quán cấu trúc: <Hành động> for sample '<id>' hoặc <Hành động> for cohort of N sample(s).
# 5.Message lỗi/cảnh báo: nêu rõ nguyên nhân + hệ quả (skip/dùng default gì).

# ------------------------- English -------------------------
# Standardize log messages for a professional style
# Style guide applied
# 1. Tense: use present continuous ("Verb-ing ...") for actions in progress, and past tense for completed actions; avoid mixing in imperative forms ("Combine", "Filter", etc.) as in the current messages.
# 2. Capitalize the first word of each sentence; avoid arbitrary capitalization mid-sentence.
# 3. Do not use "..."; express the message explicitly instead.
# 4. Keep a consistent structure: "<Action> for sample '<id>'" or "<Action> for cohort of N sample(s)".
# 5. Error/warning messages should state both the cause and the effect (e.g., what is skipped, or what default is used).

# ----------------------------------------------------------------------------------------------------
declare -A LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
)

LOG_LEVEL="INFO"
function logger() {
    local level=$1
    shift 1
    local message="$*"
    if [ ${LEVELS[$level]} -lt ${LEVELS[$LOG_LEVEL]} ]; then
        return
    fi
    timestamp=$(date -u +"%Y-%m-%d %H:%M:%S")
    case $level in
        DEBUG) color="\e[36m" ;;   # cyan
        INFO) color="\e[32m" ;;    # green
        WARN) color="\e[33m" ;;    # yellow
        ERROR) color="\e[31m" ;;   # red
    esac
    reset="\e[0m"
    # ---------- terminal (color) ----------
    # echo -e "[\e[33m$timestamp\e[0m] [${color}$level${reset}]$(printf "%*s" $((9 - ${#level} - 2)) "") $message"
    # echo -e "[\e[32m$timestamp\e[0m] [${color}$level${reset}] ${color}$message${reset}"
    echo -e "[\e[32m$timestamp\e[0m] [${color}$level${reset}] $message"
}

# ----------------------------------------------------------------------------------------------------
function require_value() {
    local argument="$1"    # tên flag, ví dụ "-t" hoặc "--threads"
    local next_value="$2"  # giá trị kế tiếp ($2 của case, tức "$2" gốc)
    local has_next="$3"    # số lượng argument còn lại ($#)

    if [[ "$has_next" -lt 2 ]]; then
        logger ERROR "$argument requires a value" >&2
        exit 3
    fi

    if [[ "$next_value" == -* ]]; then
        logger ERROR "$argument requires a value" >&2
        exit 3
    fi

    echo "$next_value"
}

function require_list_value() {
    local argument="$1"
    shift

    if [[ $# -eq 0 || "$1" == -* ]]; then
        logger ERROR "$argument requires at least one value" >&2
        exit 3
    fi

    local values=()
    for arg in "$@"; do
        if [[ "$arg" == -* ]]; then
            break
        fi
        values+=("$arg")
    done

    printf '%s\n' "${values[@]}"
}

# ----------------------------------------------------------------------------------------------------
function help() {
    echo ""
    echo "About: Run variant calling pipeline"
    echo "Usage:"
    echo ""
    echo "       forge call-variants [arguments]"
    echo ""
    echo "Arguments:"
    echo ""
    # echo "  Required arguments:"
    echo "    -I, --input <YAML>"
    echo "        Path to the YAML configuration file (e.g., run.yaml)"
    echo ""
    echo "    -O, --output <DIR>"
    echo "        Path to the directory where results will be stored (e.g., ~/result/)"
    echo ""
    echo "    -R, --reference-genome <FASTA>"
    echo "        Path to the reference genome FASTA file (e.g. hg19.fa)"
    echo ""
    # echo "  Optional arguments:"
    echo "    -r, --regions <BED>"
    echo "        Path to genomic regions to process. Accepts BED file"
    echo ""
    echo "    --bqsr-known-sites <LIST> [<VCF> ...]"
    echo "        List of known sites for Base Quality Score Recalibration (e.g., dbsnp.vcf.gz mills.vcf.gz)"
    echo ""
    echo "    --variant-types <TYPE> [<TYPE> ...]"
    echo "        One or more variant types to call, separated by a space. Allowed values: snp, indel, cnv, all (default: all)"
    echo ""
    echo "    --standard-annotation-resources <resource_name>:<file_path> [<resource_name>:<file_path> ...]"
    echo "        One or more annotation resource databases, each given as <resource_name>:<file_path>, separated by a space."
    echo ""
    echo "        Only the following <resource_name>:<file_path> values are accepted:"
    echo ""
    echo "            dbsnp138:<VCF>        dbSNP build 138 variant database"
    echo "            clinvar:<VCF>         ClinVar clinical significance annotations"
    echo "            esp6500:<VCF>         NHLBI Exome Sequencing Project population variants"
    echo "            1000g-phase3:<VCF>    1000 Genomes Project Phase 3 population frequencies"
    echo "            dbnsfp:<TXT>          dbNSFP functional prediction database"
    echo ""
    echo "            Example:"
    echo "                --standard-annotation-resource \ "
    echo "                    dbsnp138:dbsnp138.vcf.gz  \ " 
    echo "                    clinvar:clinvar.vcf.gz"
    echo ""
    echo "    -t, --threads <INT>"
    echo "        Number of threads to use (default: 4)"
    echo ""
    echo "    --min-memory <INT>"
    echo "        Minimum memory in GB (default: 8)"
    echo ""
    echo "    --max-memory <INT>"
    echo "        Maximum memory in GB (default: 16)"
    echo ""
    # echo "  Others:"
    echo "    -h, --help"
    echo "        Show this help message and exit"
}

# ----------------------------------------------------------------------------------------------------
bqsr_known_sites=()

# ----------------------------------------------------------------------------------------------------
declare -A standard_annotation_resources
valid_annotation_names=("dbsnp138" "clinvar" "esp6500" "1000g-phase3" "dbnsfp")

function is_valid_annotation_name() {
    local name="$1"
    for valid in "${valid_annotation_names[@]}"; do
        if [[ "$name" == "$valid" ]]; then
            return 0
        fi
    done
    return 1
}

# ----------------------------------------------------------------------------------------------------
valid_platforms=("illumina" "nanopore" "pacbio")

is_valid_platform() {
    local p="$1"
    for valid in "${valid_platforms[@]}"; do
        [[ "$p" == "$valid" ]] && return 0
    done
    return 1
}

# ----------------------------------------------------------------------------------------------------
variant_types=()
valid_variant_types=("snp" "indel" "cnv" "all")

is_valid_variant_type() {
    local vt="$1"
    for valid in "${valid_variant_types[@]}"; do
        [[ "$vt" == "$valid" ]] && return 0
    done
    return 1
}

# ----------------------------------------------------------------------------------------------------

if [[ $# -eq 0 ]]; then
    help
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -I|--input)
            input_file_path="$(require_value "$1" "$2" "$#")"
            shift 2
            ;;
        -O|--output)
            raw_output_dir_path="$(require_value "$1" "$2" "$#")"
            shift 2
            ;;
        -R|--reference-genome)
            reference_genome_file_path="$(require_value "$1" "$2" "$#")"
            shift 2
            ;;
        -r|--regions)
            regions_file_path="$(require_value "$1" "$2" "$#")"
            shift 2
            ;;
        --bqsr-known-sites)
            mapfile -t consumed < <(require_list_value "$1" "${@:2}")
            bqsr_known_sites+=("${consumed[@]}")
            shift $(( ${#consumed[@]} + 1 ))
            ;;
        --variant-types)
            mapfile -t consumed < <(require_list_value "$1" "${@:2}")
            shift $(( ${#consumed[@]} + 1 ))

            for vt in "${consumed[@]}"; do
                if ! is_valid_variant_type "$vt"; then
                    logger ERROR "Invalid --variant-type '${vt}'. Allowed: ${valid_variant_types[*]}"
                    exit 1
                fi

                if [[ "$vt" == "all" ]]; then
                    variant_types=("all")
                    break
                fi

                if [[ ! " ${variant_types[*]} " =~ " ${vt} " ]]; then
                    variant_types+=("$vt")
                fi
            done
            ;;
        --standard-annotation-resources)
            mapfile -t consumed < <(require_list_value "$1" "${@:2}")
            shift $(( ${#consumed[@]} + 1 ))

            for entry in "${consumed[@]}"; do
                if [[ "$entry" != *:* ]]; then
                    logger WARN "Skipping '$entry' — expected format <resource_name>:<file_path>" >&2
                    continue
                fi

                db_name="${entry%%:*}"
                db_path="${entry#*:}"

                if ! is_valid_annotation_name "$db_name"; then
                    logger WARN "Skipping unknown annotation resource '$db_name'" >&2
                    continue
                fi

                if [[ -v standard_annotation_resources["$db_name"] ]]; then
                    logger WARN "Skipping duplicate annotation resource '$db_name'" >&2
                    continue
                fi

                standard_annotation_resources["$db_name"]="$db_path"
            done
            ;;
        -t|--threads)
            threads="$(require_value "$1" "$2" "$#")"
            shift 2
            ;;  
        --min-memory)
            min_memory_gb="$(require_value "$1" "$2" "$#")"
            shift 2
            ;; 

        --max-memory)
            max_memory_gb="$(require_value "$1" "$2" "$#")"
            shift 2
            ;;   
        -h|--help)
            help
            exit 0
            ;;
        -*)
            logger ERROR "Unknown option: $1" >&2
            help
            exit 1 
            ;;
        *)
            logger ERROR "Unexpected argument: $1" >&2
            exit 1
            ;;
    esac
done
#==================================================#
#         VALIDATE REQUIRED ARGUMENTS              #
#==================================================#

if [[ -z "${input_file_path:-}" ]]; then
    logger ERROR "Missing required argument: -I|--input"
    exit 1
fi

if [[ -z "${raw_output_dir_path:-}" ]]; then
    logger ERROR "Missing required argument: -O|--output"
    exit 1
fi

utc_time="$(date -u +"%Y-%m-%d_%Hh-%Mm-%Ss_UTC")"
workflow_title="call-variants"
output_dir_path="${raw_output_dir_path%/}/${utc_time}_${workflow_title}"

if [[ -z "${reference_genome_file_path:-}" ]]; then
    logger ERROR "Missing required argument: -R|--reference-genome"
    exit 1
fi

if [[ ! -f "$input_file_path" ]]; then
    logger ERROR "Input file not found: $input_file_path"
    exit 1
fi

if [[ ! -f "$reference_genome_file_path" ]]; then
    logger ERROR "Reference genome file not found: $reference_genome_file_path"
    exit 1
fi

#==================================================#
#         VALIDATE OPTIONAL ARGUMENTS               #
#==================================================#

# --regions (optional, nhưng nếu có truyền thì file phải tồn tại)
if [[ -n "${regions_file_path:-}" && ! -f "$regions_file_path" ]]; then
    logger ERROR "Regions file not found: $regions_file_path"
    exit 1
fi

# --bqsr-known-sites (optional, cảnh báo nếu file không tồn tại, không exit)
for site in "${bqsr_known_sites[@]}"; do
    if [[ ! -f "$site" ]]; then
        logger WARN "Excluding missing BQSR known-sites file: $site"
    fi
done

# --variant-type: mặc định "all" nếu không truyền
if [[ ${#variant_types[@]} -eq 0 ]]; then
    variant_types=("all")
fi

# --threads: mặc định 4, phải là số nguyên dương
threads="${threads:-4}"
if ! [[ "$threads" =~ ^[0-9]+$ ]] || [[ "$threads" -lt 1 ]]; then
    logger ERROR "Invalid value for --threads: '${threads}' (must be a positive integer)"
    exit 1
fi

# --min-memory: mặc định 8, phải là số nguyên dương
min_memory_gb="${min_memory_gb:-8}"
if ! [[ "$min_memory_gb" =~ ^[0-9]+$ ]] || [[ "$min_memory_gb" -lt 1 ]]; then
    logger ERROR "--min-memory must be a positive integer, got '${min_memory_gb}'"
    exit 1
fi

# --max-memory: mặc định 16, phải là số nguyên dương
max_memory_gb="${max_memory_gb:-16}"
if ! [[ "$max_memory_gb" =~ ^[0-9]+$ ]] || [[ "$max_memory_gb" -lt 1 ]]; then
    logger ERROR "--max-memory must be a positive integer, got '${max_memory_gb}'"
    exit 1
fi

# min-memory không được lớn hơn max-memory
if [[ "$min_memory_gb" -gt "$max_memory_gb" ]]; then
    logger ERROR "--min-memory (${min_memory_gb} GB) exceeds --max-memory (${max_memory_gb} GB)"
    exit 1
fi

# --standard-annotation-resources: cảnh báo nếu file không tồn tại (không exit, vì đã validate tên ở bước parse)
for db_name in "${!standard_annotation_resources[@]}"; do
    db_path="${standard_annotation_resources[$db_name]}"
    if [[ ! -f "$db_path" ]]; then
        logger WARN "Excluding annotation resource '$db_name': file not found ($db_path)"
        unset "standard_annotation_resources[$db_name]"
    fi
done

logger INFO "All arguments validated successfully"

parse_sample_config() {
    local config_path="$1"

    if [[ ! -f "$config_path" ]]; then
        logger ERROR "Cannot find sample configuration file: $config_path"
        exit 1
    fi

    if ! yq -o=json '.sample' "$config_path" > /tmp/samples.json 2>/tmp/yq_err.log; then
        logger ERROR "Failed to parse sample configuration YAML: $(cat /tmp/yq_err.log)"
        exit 1
    fi

    mapfile -t samples < <(jq -c '.[]' /tmp/samples.json)

    if [[ ${#samples[@]} -eq 0 ]]; then
        logger ERROR "No samples defined in configuration file: $config_path"
        exit 1
    fi

    for sample_json in "${samples[@]}"; do
        id=$(jq -r '.id // empty' <<< "$sample_json")
        platform=$(jq -r '.platform // empty' <<< "$sample_json")
        read1=$(jq -r '.read1 // empty' <<< "$sample_json")
        read2=$(jq -r '.read2 // empty' <<< "$sample_json")

        if [[ -z "$id" || -z "$platform" || -z "$read1" || -z "$read2" ]]; then
            logger ERROR "Sample is missing one or more required fields: $sample_json"
            exit 1
        fi

        if ! is_valid_platform "$platform"; then
            logger ERROR "Unsupported platform '$platform' for sample '$id'. Supported platforms: ${valid_platforms[*]}"
            exit 1
        fi

        if [[ ! -f "$read1" ]]; then
            logger ERROR "Cannot find read1 file for sample '$id': $read1"
            exit 1
        fi

        if [[ ! -f "$read2" ]]; then
            logger ERROR "Cannot find read2 file for sample '$id': $read2"
            exit 1
        fi
    done

    logger INFO "Loaded ${#samples[@]} sample(s) from configuration file: $config_path"
    rm -f /tmp/samples.json /tmp/yq_err.log
}

contains_variant_type() {
    local target="$1"
    for vt in "${variant_types[@]}"; do
        [[ "$vt" == "all" || "$vt" == "$target" ]] && return 0
    done
    return 1
}

should_run_snp_indel() {
    contains_variant_type "snp" || contains_variant_type "indel"
}

should_run_cnv() {
    contains_variant_type "cnv"
}

# DEBUG
echo $input_file_path
echo $output_dir_path
echo $reference_genome_file_path
echo $regions_file_path

for bqsr_known_site in "${bqsr_known_sites[@]}"; do
    echo "$bqsr_known_site"
done

for db_name in "${!standard_annotation_resources[@]}"; do
    db_path="${standard_annotation_resources[$db_name]}"
    echo "DB=$db_name  PATH=$db_path"
done

parse_sample_config "$input_file_path"
echo "${#samples[@]}"
echo "${samples[0]}"   

cyan_color="\e[36m"  # cyan
green_color="\e[32m"   # green
yellow_color="\e[33m" # yellow
red_color="\e[31m"   # red
reset="\e[0m"

BQSR_FLAGS=()
for site in "${bqsr_known_sites[@]}"; do
    [ -f "$site" ] && BQSR_FLAGS+=(--known-sites "$site")
done

echo "${BQSR_FLAGS[@]}"

GVCF_COMBINE_FLAGS=()

mkdir -p "$output_dir_path/log" 
WORKFLOW_RUNTIME_LOG_FILE_PATH="$output_dir_path/log/workflow.runtime.log"

function main() {

    #==================================================#
    #              WORKFLOW INITIALIZATION             #
    #==================================================#
    mkdir -p "$output_dir_path"

    jq -n \
        --arg workflow_title "call-variants" \
        --arg UTC_time "$(date -u +"%Y-%m-%d %H:%M:%S")" \
        --arg local_time "$(date +"%Y-%m-%d %H:%M:%S")" \
        --arg UUIDv4 "$(uuidgen -r)" \
        --arg input_file_path "$input_file_path" \
        --arg output_dir_path "$output_dir_path" \
        --arg reference_genome_file_path "$reference_genome_file_path" \
        --arg regions_file_path "$regions_file_path" \
        --argjson threads "${threads:-0}" \
        --argjson min_memory_gb "$min_memory_gb" \
        --argjson max_memory_gb "$max_memory_gb" \
        --argjson variant_types "$(printf '%s\n' "${variant_types[@]}" | jq -R . | jq -s .)" \
        --argjson bqsr_known_sites "$(printf '%s\n' "${bqsr_known_sites[@]}" | jq -R . | jq -s .)" \
        --argjson standard_annotation_resources "$(
            for key in "${!standard_annotation_resources[@]}"; do
                jq -n --arg k "$key" --arg v "${standard_annotation_resources[$key]}" '{($k): $v}'
            done | jq -s 'add // {}'
        )" \
        '{
            workflow_title: $workflow_title,
            UTC_time: $UTC_time,
            local_time: $local_time,
            UUIDv4: $UUIDv4,
            context: {
                input_file_path: $input_file_path,
                output_dir_path: $output_dir_path,
                reference_genome_file_path: $reference_genome_file_path,
                regions_file_path: $regions_file_path,
                threads: $threads,
                min_memory_gb: $min_memory_gb,
                max_memory_gb: $max_memory_gb,
                variant_types: $variant_types,
                bqsr_known_sites: $bqsr_known_sites,
                standard_annotation_resources: $standard_annotation_resources
            }
        }' > "$output_dir_path/workflow.metadata.json"
    
    #==================================================#
    #              SECONDARY DATA ANALYSIS             #
    #==================================================#

    for sample in "${samples[@]}"; do
        # Extract sample metadata for the workflow
        sample_id=$(jq -r '.id' <<< "$sample")

        mkdir -p "${output_dir_path}/${sample_id}"   # Create a subdirectory for each sample inside the output directory
        GVCF_COMBINE_FLAGS+=(
            -V "${output_dir_path}/${sample_id}/${sample_id}.g.vcf"
        )
    done

    for sample in "${samples[@]}"; do
        # Extract sample metadata for the workflow
        sample_id=$(jq -r '.id' <<< "$sample")
        sample_platform=$(jq -r '.platform' <<< "$sample")
        sample_read1=$(jq -r '.read1' <<< "$sample")
        sample_read2=$(jq -r '.read2' <<< "$sample")

        # Mapping and alignment
        logger INFO "Mapping and Aligning ${green_color}$sample_id${reset} reads to reference genome" 

        /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" bash -c "
            bwa mem -t ${threads} \
                -R \"@RG\tID:${sample_id}\tLB:lib1\tPL:${sample_platform}\tPU:unit1\tSM:${sample_id}\" \
                \"${reference_genome_file_path}\" \
                \"${sample_read1}\" \
                \"${sample_read2}\" | \
            samtools sort -@ ${threads} -o \"${output_dir_path}/${sample_id}/${sample_id}.sorted.bam\"
        "
    done

    for sample in "${samples[@]}"; do
        # Extract sample metadata for the workflow
        sample_id=$(jq -r '.id' <<< "$sample")

        # Mark duplicate reads
        logger INFO "Marking duplicate reads for sample ${green_color}$sample_id${reset}"

        /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
            gatk MarkDuplicates \
                -I "${output_dir_path}/${sample_id}/${sample_id}.sorted.bam" \
                -O "${output_dir_path}/${sample_id}/${sample_id}.sorted.marked.bam" \
                --REMOVE_DUPLICATES true \
                --ASSUME_SORTED true \
                --TMP_DIR "${output_dir_path}/${sample_id}/" \
                --VALIDATION_STRINGENCY SILENT \
                -M "${output_dir_path}/${sample_id}/${sample_id}.output.metrics.txt"
        
        /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
            samtools index "${output_dir_path}/${sample_id}/${sample_id}.sorted.marked.bam"

    done
    #====================================================================================================#
    #                                     SNP AND INDEL VARIANTS                                         #
    #====================================================================================================#
    if should_run_snp_indel; then
        logger INFO "Starting SNP/Indel variant calling (requested types: ${variant_types[*]})"

        for sample in "${samples[@]}"; do
            # Extract sample metadata for the workflow
            sample_id=$(jq -r '.id' <<< "$sample")

            # Recalibrate base quality and apply BQSR
            if [ ${#BQSR_FLAGS[@]} -eq 0 ]; then
                logger WARN "Skipping base quality score recalibration for sample ${green_color}$sample_id${reset} (no BQSR known sites provided)"
                cp "${output_dir_path}/${sample_id}/${sample_id}.sorted.marked.bam" \
                    "${output_dir_path}/${sample_id}/${sample_id}.final.bam"
            else
                logger INFO "Building base quality score recalibration table for sample ${green_color}$sample_id${reset}"

                /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                    gatk BaseRecalibrator \
                        -I "${output_dir_path}/${sample_id}/${sample_id}.sorted.marked.bam" \
                        -R "${reference_genome_file_path}" \
                        "${BQSR_FLAGS[@]}" \
                        -O "${output_dir_path}/${sample_id}/${sample_id}.recal_data.table" \
                        --intervals "${regions_file_path}" \
                        --interval-padding 100

                logger INFO "Applying base quality score recalibration for sample ${green_color}$sample_id${reset}"

                /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                    gatk ApplyBQSR \
                        -I "${output_dir_path}/${sample_id}/${sample_id}.sorted.marked.bam" \
                        -R "${reference_genome_file_path}" \
                        --bqsr-recal-file "${output_dir_path}/${sample_id}/${sample_id}.recal_data.table" \
                        -O "${output_dir_path}/${sample_id}/${sample_id}.sorted.marked.recalibrated.bam" \
                        --intervals "${regions_file_path}" \
                        --interval-padding 100

                cp "${output_dir_path}/${sample_id}/${sample_id}.sorted.marked.recalibrated.bam" \
                    "${output_dir_path}/${sample_id}/${sample_id}.final.bam"

                /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                    samtools index "${output_dir_path}/${sample_id}/${sample_id}.final.bam"
            fi
        done

        for sample in "${samples[@]}"; do
            # Extract sample metadata for the workflow
            sample_id=$(jq -r '.id' <<< "$sample")

            # Call variants
            logger INFO "Calling variants (GVCF mode) for sample ${green_color}$sample_id${reset}"

            /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                gatk HaplotypeCaller \
                    -I "${output_dir_path}/${sample_id}/${sample_id}.final.bam" \
                    -R "${reference_genome_file_path}" \
                    -O "${output_dir_path}/${sample_id}/${sample_id}.g.vcf" \
                    --native-pair-hmm-threads ${threads} \
                    -ERC GVCF \
                    -L "${regions_file_path}" \
                    -ip 100 \
                    --use-posteriors-to-calculate-qual false \
                    --dont-use-dragstr-priors false \
                    --use-new-qual-calculator true \
                    --annotate-with-num-discovered-alleles false \
                    --heterozygosity 0.001 \
                    --indel-heterozygosity 1.25E-4 \
                    --heterozygosity-stdev 0.01 \
                    --standard-min-confidence-threshold-for-calling 30.0 \
                    --max-alternate-alleles 6 \
                    --max-genotype-count 1024 \
                    --sample-ploidy 2 \
                    --num-reference-samples-if-no-call 0 \
                    --genotype-assignment-method USE_PLS_TO_ASSIGN \
                    --contamination-fraction-to-filter 0.0 \
                    --output-mode EMIT_VARIANTS_ONLY \
                    --minimum-mapping-quality 20 \
                    --base-quality-score-threshold 18 \
                    --pcr-indel-model CONSERVATIVE \
                    --likelihood-calculation-engine PairHMM \
                    --gvcf-gq-bands 1 --gvcf-gq-bands 2 --gvcf-gq-bands 3 --gvcf-gq-bands 4 \
                    --gvcf-gq-bands 5 --gvcf-gq-bands 6 --gvcf-gq-bands 7 --gvcf-gq-bands 8 \
                    --gvcf-gq-bands 9 --gvcf-gq-bands 10 --gvcf-gq-bands 11 --gvcf-gq-bands 12 \
                    --gvcf-gq-bands 13 --gvcf-gq-bands 14 --gvcf-gq-bands 15 --gvcf-gq-bands 16 \
                    --gvcf-gq-bands 17 --gvcf-gq-bands 18 --gvcf-gq-bands 19 --gvcf-gq-bands 20 \
                    --gvcf-gq-bands 21 --gvcf-gq-bands 22 --gvcf-gq-bands 23 --gvcf-gq-bands 24 \
                    --gvcf-gq-bands 25 --gvcf-gq-bands 26 --gvcf-gq-bands 27 --gvcf-gq-bands 28 \
                    --gvcf-gq-bands 29 --gvcf-gq-bands 30 --gvcf-gq-bands 31 --gvcf-gq-bands 32 \
                    --gvcf-gq-bands 33 --gvcf-gq-bands 34 --gvcf-gq-bands 35 --gvcf-gq-bands 36 \
                    --gvcf-gq-bands 37 --gvcf-gq-bands 38 --gvcf-gq-bands 39 --gvcf-gq-bands 40 \
                    --gvcf-gq-bands 41 --gvcf-gq-bands 42 --gvcf-gq-bands 43 --gvcf-gq-bands 44 \
                    --gvcf-gq-bands 45 --gvcf-gq-bands 46 --gvcf-gq-bands 47 --gvcf-gq-bands 48 \
                    --gvcf-gq-bands 49 --gvcf-gq-bands 50 --gvcf-gq-bands 51 --gvcf-gq-bands 52 \
                    --gvcf-gq-bands 53 --gvcf-gq-bands 54 --gvcf-gq-bands 55 --gvcf-gq-bands 56 \
                    --gvcf-gq-bands 57 --gvcf-gq-bands 58 --gvcf-gq-bands 59 --gvcf-gq-bands 60 \
                    --gvcf-gq-bands 70 --gvcf-gq-bands 80 --gvcf-gq-bands 90 --gvcf-gq-bands 99 \
                    --read-validation-stringency SILENT \
                    --verbosity INFO
        done
        sample_ids=()
        for sample in "${samples[@]}"; do
            sample_ids+=("$(jq -r '.id' <<< "$sample")")
        done
        sample_ids_joined=$(IFS=", "; echo "${sample_ids[*]}")

        # Combining GVCF files
        logger INFO "Combining GVCF files for cohort: ${green_color}${sample_ids_joined}${reset}" 

        /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
            gatk CombineGVCFs \
                -R "${reference_genome_file_path}" \
                "${GVCF_COMBINE_FLAGS[@]}" \
                -O "${output_dir_path}/cohort.g.vcf"

        # Genotype combined GVCF
        logger INFO "Genotyping combined GVCF for cohort: ${green_color}${sample_ids_joined}${reset}"

        /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
            gatk GenotypeGVCFs \
                -R "${reference_genome_file_path}" \
                -V "${output_dir_path}/cohort.g.vcf" \
                -O "${output_dir_path}/cohort.vcf" \
                -L "${regions_file_path}" \
                -ip 100 \
                --include-non-variant-sites false \
                --merge-input-intervals false \
                --input-is-somatic false \
                --tumor-lod-to-emit 3.5 \
                --allele-fraction-error 0.001 \
                --keep-combined-raw-annotations false \
                --use-posteriors-to-calculate-qual false \
                --use-new-qual-calculator true \
                --standard-min-confidence-threshold-for-calling 30.0 \
                --max-alternate-alleles 6 \
                --sample-ploidy 2 \
                --genotype-assignment-method USE_PLS_TO_ASSIGN \
                --call-genotypes false \
                --interval-set-rule UNION \
                --interval-merging-rule ALL \
                --read-validation-stringency SILENT \
                --verbosity INFO

        # Filter variants
        logger INFO "Filtering variants for cohort: ${green_color}${sample_ids_joined}${reset}"
        /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
            gatk VariantFiltration \
                -R "${reference_genome_file_path}" \
                -V "${output_dir_path}/cohort.vcf" \
                --filter-expression 'vc.isSNP() && (QD < 2.0 || FS > 60.0 || MQ < 40.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0 || SOR > 3.0)' \
                --filter-name "MG_SNP_Filter" \
                --filter-expression 'vc.isIndel() && (QD < 2.0 || FS > 200.0 || ReadPosRankSum < -20.0)' \
                --filter-name "MG_INDEL_Filter" \
                -O "${output_dir_path}/cohort.filtered.vcf"

        # Normalize combined VCF
        logger INFO "Normalizing filtered VCF for cohort: ${green_color}${sample_ids_joined}${reset}"

        /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
            bcftools norm -Ov -m-any \
                --multi-overlaps . \
                "${output_dir_path}/cohort.filtered.vcf" \
                -o "${output_dir_path}/cohort.filtered.normalized.vcf"

        #==================================================#
        #             TERTIARY DATA ANALYSIS               #
        #==================================================#

        # Annotate variants with genomic information
        logger INFO "Annotating variants with genomic information for cohort: ${green_color}${sample_ids_joined}${reset}"

        /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
            snpEff -Xmx${max_memory_gb}g -noStats -v GRCh37.p13 \
                "${output_dir_path}/cohort.filtered.normalized.vcf" \
                > "${output_dir_path}/cohort.filtered.normalized.annotated.temp_001.vcf"

        # Annotate variants with variant type
        logger INFO "Annotating variants with variant type classification for cohort: ${green_color}${sample_ids_joined}${reset}"

        /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
            SnpSift -Xmx${max_memory_gb}g varType \
                "${output_dir_path}/cohort.filtered.normalized.annotated.temp_001.vcf" \
                > "${output_dir_path}/cohort.filtered.normalized.annotated.temp_002.vcf"

        # Annotate variants with ClinVar database
        if [[ -n "${standard_annotation_resources[clinvar]:-}" && -f "${standard_annotation_resources[clinvar]:-}" ]]; then
            logger INFO "Annotating variants with ClinVar database for cohort: ${green_color}${sample_ids_joined}${reset}"  

            /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                SnpSift -Xmx${max_memory_gb}g annotate \
                    -noId -name CLINVAR_ \
                    "${standard_annotation_resources[clinvar]:-}" \
                    "${output_dir_path}/cohort.filtered.normalized.annotated.temp_002.vcf" \
                    > "${output_dir_path}/cohort.filtered.normalized.annotated.temp_003.vcf"
        else
            logger WARN "Skipping ClinVar annotation (no database file provided)"
            cp "${output_dir_path}/cohort.filtered.normalized.annotated.temp_002.vcf" \
                "${output_dir_path}/cohort.filtered.normalized.annotated.temp_003.vcf"
        fi

        # Annotate variants with 1000G phase3 database
        if [[ -n "${standard_annotation_resources[1000g-phase3]:-}" && -f "${standard_annotation_resources[1000g-phase3]:-}" ]]; then
            logger INFO "Annotating variants with 1000 Genomes Phase 3 database for cohort: ${green_color}${sample_ids_joined}${reset}"

            /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                SnpSift -Xmx${max_memory_gb}g annotate \
                    -noId -name p3_1000G_ \
                    "${standard_annotation_resources[1000g-phase3]:-}" \
                    "${output_dir_path}/cohort.filtered.normalized.annotated.temp_003.vcf"  \
                    > "${output_dir_path}/cohort.filtered.normalized.annotated.temp_004.vcf"
        else
            logger WARN "Skipping 1000 Genomes Phase 3 annotation (no database file provided)"
            cp "${output_dir_path}/cohort.filtered.normalized.annotated.temp_003.vcf" \
                "${output_dir_path}/cohort.filtered.normalized.annotated.temp_004.vcf"
        fi

        # Annotate variants with ESP6500 database
        if [[ -n "${standard_annotation_resources[esp6500]:-}" && -f "${standard_annotation_resources[esp6500]:-}" ]]; then
            logger INFO "Annotating variants with ESP6500 database for cohort: ${green_color}${sample_ids_joined}${reset}"

            /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                SnpSift -Xmx${max_memory_gb}g annotate \
                    -noId -name ESP6500_ \
                    "${standard_annotation_resources[esp6500]:-}" \
                    "${output_dir_path}/cohort.filtered.normalized.annotated.temp_004.vcf"  \
                    > "${output_dir_path}/cohort.filtered.normalized.annotated.temp_005.vcf"
        else
            logger WARN "Skipping ESP6500 annotation (no database file provided)"
            cp "${output_dir_path}/cohort.filtered.normalized.annotated.temp_004.vcf" \
                "${output_dir_path}/cohort.filtered.normalized.annotated.temp_005.vcf"
        fi

        # Annotate variants with dbSNP 138
        if [[ -n "${standard_annotation_resources[dbsnp138]:-}" && -f "${standard_annotation_resources[dbsnp138]:-}" ]]; then
            logger INFO "Annotating variants with dbSNP build 138 database for cohort: ${green_color}${sample_ids_joined}${reset}"

            /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                SnpSift -Xmx${max_memory_gb}g annotate \
                    -noId -info dbSNP138_ID,dbSNPBuildID \
                    -id \
                    "${standard_annotation_resources[dbsnp138]:-}" \
                    "${output_dir_path}/cohort.filtered.normalized.annotated.temp_005.vcf" \
                    > "${output_dir_path}/cohort.filtered.normalized.annotated.temp_006.vcf"
        else
            logger WARN "Skipping dbSNP 138 annotation (no database file provided)"
            cp "${output_dir_path}/cohort.filtered.normalized.annotated.temp_005.vcf" \
                "${output_dir_path}/cohort.filtered.normalized.annotated.temp_006.vcf"
        fi

        # Annotate variants with dbNSFP database
        if [[ -n "${standard_annotation_resources[dbnsfp]:-}" && -f "${standard_annotation_resources[dbnsfp]:-}" ]]; then
            logger INFO "Annotating variants with dbNSFP database for cohort: ${green_color}${sample_ids_joined}${reset}"   

            /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                SnpSift -Xmx${max_memory_gb}g dbnsfp -v -f '' -n \
                    -db "${standard_annotation_resources[dbnsfp]:-}" \
                    "${output_dir_path}/cohort.filtered.normalized.annotated.temp_006.vcf" \
                    > "${output_dir_path}/cohort.filtered.normalized.annotated.temp_007.vcf"
        else
            logger WARN "Skipping dbNSFP annotation (no database file provided)"
            cp "${output_dir_path}/cohort.filtered.normalized.annotated.temp_006.vcf" \
                "${output_dir_path}/cohort.filtered.normalized.annotated.temp_007.vcf"
        fi

        # ---------- Select Variants ----------

        if contains_variant_type "all" || (contains_variant_type "snp" && contains_variant_type "indel"); then
            extension="SNPs_and_INDELs"
            select_type_flags=()
        elif contains_variant_type "snp"; then
            extension="SNPs" # Single Nucleotide Polymorphisms
            select_type_flags=(--select-type-to-include SNP)
        elif contains_variant_type "indel"; then
            extension="INDELs" # Insertions and Deletions
            select_type_flags=(--select-type-to-include INDEL)
        fi

        for sample in "${samples[@]}"; do
            sample_id=$(jq -r '.id' <<< "$sample")
            logger INFO "Extracting sample-level variants for ${green_color}$sample_id${reset}"

            /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                gatk SelectVariants \
                    -V "${output_dir_path}/cohort.filtered.normalized.annotated.temp_007.vcf" \
                    -R "${reference_genome_file_path}" \
                    --sample-name "${sample_id}" \
                    --exclude-non-variants \
                    "${select_type_flags[@]}" \
                    -O "${output_dir_path}/${sample_id}/${sample_id}.final.vcf"
        done
        
        for sample in "${samples[@]}"; do
            sample_id=$(jq -r '.id' <<< "$sample")

            logger INFO "Generating SNP/Indel variant report (XLSX) for sample ${green_color}$sample_id${reset}"

            if [ -f "$SCRIPT_DIR_PATH/generate_snp_and_indel_variants_xlsx_report.py" ]; then
                /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                python3 "$SCRIPT_DIR_PATH/generate_snp_and_indel_variants_xlsx_report.py" \
                    -I "${output_dir_path}/${sample_id}/${sample_id}.final.vcf" \
                    -O "${output_dir_path}/${sample_id}/${sample_id}.${extension}.xlsx" 
            else 
                /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                    python3 - \
                        -I "${output_dir_path}/${sample_id}/${sample_id}.final.vcf" \
                        -O "${output_dir_path}/${sample_id}/${sample_id}.${extension}.xlsx" \
                        << 'PYTHON'
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
PYTHON
            fi
        done
    else
        logger INFO "Skipping SNP/Indel variant calling (requested types: ${variant_types[*]})"
    fi

    #====================================================================================================#
    #                                       COPY NUMBER VARIANTS                                         #
    #====================================================================================================#
    if should_run_cnv; then
        logger INFO "Starting copy number variant (CNV) calling (requested types: ${variant_types[*]})"

        # In the reference genome sequence these regions are filled in with large stretches of “N” characters. These regions cannot be mapped by resequencing, so CNVkit avoids them when calculating the antitarget bin locations by "cnvkit.py access"
        /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
            cnvkit access "${reference_genome_file_path}" \
                -o "${output_dir_path}/access.reference.bed"

        regions_basename="$(basename "${regions_file_path%.bed}")"
        antitarget_regions_file_path="${output_dir_path}/${regions_basename}.antitargets.bed"
        /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
            cnvkit antitarget \
                "${regions_file_path}" \
                -g "${output_dir_path}/access.reference.bed" \
                -o "${antitarget_regions_file_path}"

        /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
            cnvkit autobin \
                "${output_dir_path}"/*/*.sorted.marked.bam \
                -t "${regions_file_path}" \
                -g "${output_dir_path}/access.reference.bed" 

        /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
            cnvkit reference \
                -o "${output_dir_path}/flat_reference.cnn" \
                -f "${reference_genome_file_path}" \
                -t "${regions_file_path}" \
                -a "${antitarget_regions_file_path}"

        # Mẫu khối u, Nếu có mẫu thường tương ứng thì lặp qua các mẫu thường tương tự để thu các file .cnn
        for sample in "${samples[@]}"; do
            sample_id=$(jq -r '.id' <<< "$sample")
            /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                cnvkit coverage \
                    "${output_dir_path}/${sample_id}/${sample_id}.sorted.marked.bam" \
                    "${regions_file_path}" \
                    -f "${reference_genome_file_path}" \
                    -o "${output_dir_path}/${sample_id}/${sample_id}.targetcoverage.cnn"

            /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                cnvkit coverage \
                    "${output_dir_path}/${sample_id}/${sample_id}.sorted.marked.bam" \
                    "${antitarget_regions_file_path}" \
                    -f "${reference_genome_file_path}" \
                    -o "${output_dir_path}/${sample_id}/${sample_id}.antitargetcoverage.cnn"
        done

        for sample in "${samples[@]}"; do
            sample_id=$(jq -r '.id' <<< "$sample")

            /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                cnvkit fix \
                    "${output_dir_path}/${sample_id}/${sample_id}.targetcoverage.cnn" \
                    "${output_dir_path}/${sample_id}/${sample_id}.antitargetcoverage.cnn" \
                    "${output_dir_path}/flat_reference.cnn" \
                    -o "${output_dir_path}/${sample_id}/${sample_id}.cnr"

            /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                cnvkit segment \
                    "${output_dir_path}/${sample_id}/${sample_id}.cnr" \
                    -o "${output_dir_path}/${sample_id}/${sample_id}.cns"
            
            /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                cnvkit call \
                    "${output_dir_path}/${sample_id}/${sample_id}.cns" \
                    -o "${output_dir_path}/${sample_id}/${sample_id}.call.cns"
            
            if [ -f "$SCRIPT_DIR_PATH/generate_copy_number_variants_xlsx_report.py" ]; then
                /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                    python3 "$SCRIPT_DIR_PATH/generate_copy_number_variants_xlsx_report.py" \
                        -I "${output_dir_path}/${sample_id}/${sample_id}.call.cns" \
                        -O "${output_dir_path}/${sample_id}/${sample_id}.CNVs.xlsx"
            else 
                /usr/bin/time -v -a -o "${WORKFLOW_RUNTIME_LOG_FILE_PATH}" \
                    python3 - \
                        -I "${output_dir_path}/${sample_id}/${sample_id}.call.cns" \
                        -O "${output_dir_path}/${sample_id}/${sample_id}.CNVs.xlsx" \
                        << 'PYTHON'
import argparse
import pandas as pd
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

HEADER = [
    "CHROM", "START", "END", "GENE", "Log2", "COPY NUMBER", "DEPTH", "P_TTEST", "PROBES", "WEIGHT"
]

NEW_HEADER = [
    "CHROM", "START", "END", "Log2", "COPY NUMBER", "DEPTH", "P_TTEST", "PROBES", "WEIGHT", "GENE"
]

data_frame = pd.read_csv(
    input_file_path,
    sep="\t",
    skiprows=1,
    header=None,
    names=HEADER
)
data_frame = data_frame[NEW_HEADER]

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

    wrap_format = workbook.add_format({
        'text_wrap': True,
    })

    for i, col in enumerate(data_frame.columns):
        if col == "COPY NUMBER":
            worksheet.set_column(i, i, 20, wrap_format)
        else:
            worksheet.set_column(i, i, 15, wrap_format)
    # Set filter for the header row
    worksheet.autofilter(0, 0, 0, len(data_frame.columns)-1)

    row_height = 1 * 20
    worksheet.set_row(0, row_height)

    for row_num in range(1, len(data_frame_filled) + 1):
        worksheet.set_row(row_num, 15.5, data_format)
PYTHON
            fi
        done
    else
        logger INFO "Skipping copy number variant (CNV) calling (requested types: ${variant_types[*]})"
    fi

}

main