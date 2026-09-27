#/bin/bash

set -Eeuo pipefail

SCRIPT_DIR_PATH="$(dirname "$(realpath "$0")")"

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

function help() {
    echo ""
    echo "Program: Workflow for NGS data analysis"
    echo "License: GNU General Public License Version 3, 29 June 2007"
    echo "Contact: La Kieu Ngoc Quyet <quyetlakn@gmail.com>"
    echo ""
    echo "Usage:"
    echo ""
    echo "       ngs_pipeline <command> [arguments]"
    echo ""
    echo "Commands:"
    echo ""
    echo "  Workflow commands:"
    echo "    call-variants         Run variant calling pipeline"
    echo ""
    echo "  Others:"
    echo "    -h, --help            Show this help message and exit"
    echo ""
    echo "Use 'ngs_pipeline <command> -h' for more information on a command."
}

if [[ $# -eq 0 ]]; then
    help
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        call-variants)
            shift
            script_path="$SCRIPT_DIR_PATH/call_variants.sh"
            if [[ ! -f "$script_path" ]]; then
                echo "Error: Cannot find $script_path" >&2
                exit 1
            fi
            bash "$script_path" "$@"
            exit $?
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
