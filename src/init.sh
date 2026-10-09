set -Eeuo pipefail
SCRIPT_DIR_PATH="$(dirname "$(realpath "$0")")"

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
    echo "About: Generate a template input YAML file to start a pipeline"
    echo "Usage:"
    echo ""
    echo "       ngs-pipeline init [arguments]"
    echo ""
    echo "Arguments:"
    echo ""
    echo "    Required arguments:"
    echo "    -pl, --pipeline <PIPELINE_NAME>"
    echo "        Pipeline name to generate a template YAML file"
    echo ""
    echo "    -o, --output-file <FILE>"
    echo "        Output file path (default: <PIPELINE_NAME>.yaml)."
    echo ""
    echo "    Optional arguments:"
    echo "    -N, --number-of-samples <INT>"
    echo "        Number of samples (default: 1)"
    echo ""
    echo "    Others:"
    echo "    -h, --help"
    echo "        Show this help message and exit"
}

# ----------------------------------------------------------------------------------------------------
template_call_variants() {
    local n=$1
    echo "# Please don't use tab characters for indentation in this file. Use spaces only."
    echo "sample:"
    for ((i = 0; i < n; i++)); do
        cat <<'EOF'
  - id:        # sample id
    read1:     # path/to/read1/fastq/file
    read2:     # path/to/read2/fastq/file
EOF
    done
}

generate_template_yaml() {
    local pipeline_name=$1
    local output_file=$2
    local number_of_samples=${3:-1}

    case "$pipeline_name" in
        call-variants)        
            template_call_variants "$number_of_samples" > "$output_file" 
            ;;
        *)
            return 1
            ;;
    esac
}

pipeline=""
output_file_path=""
number_of_samples=""
#==================================================#
#                   PARSE ARGUMENTS                #
#==================================================#
if [[ $# -eq 0 ]]; then
    help
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -pl|--pipeline)
            pipeline="$(require_value "$1" "$2" "$#")"
            shift 2
            ;;
        -N|--number-of-samples)
            number_of_samples="$(require_value "$1" "$2" "$#")"
            shift 2
            ;;
        -o|--output-file)
            output_file_path="$(require_value "$1" "$2" "$#")"
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
#             VALIDATE OPTIONAL ARGUMENTS          #
#==================================================#
if [[ -z "$pipeline" ]]; then
    logger ERROR "Missing required argument: -pl/--pipeline" >&2
    exit 3
fi

number_of_samples="${number_of_samples:-1}"
if ! [[ "$number_of_samples" =~ ^[0-9]+$ ]] || [[ "$((10#$number_of_samples))" -lt 1 ]]; then
    logger ERROR "Invalid value for --number-of-samples: '${number_of_samples}' (must be a positive integer)" >&2
    exit 1
fi
number_of_samples=$((10#$number_of_samples)) # ép kiểu dữ liệu của biến về hệ cơ số 10 (thập phân)

function init() {
    local output_file="${output_file_path:-${pipeline}.yaml}"

    if [[ -e "$output_file" ]]; then
        logger WARN "Skipping '$output_file', file already exists"
        return 0
    fi

    if ! generate_template_yaml "$pipeline" "$output_file" "$number_of_samples"; then
        logger ERROR "Unknown pipeline: $pipeline" >&2
        exit 1
    fi
    logger INFO "Created $output_file"
}

init