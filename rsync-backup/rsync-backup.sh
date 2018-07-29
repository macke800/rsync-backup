#!/usr/bin/env bash

set -o err_exit
set -o pipefail
set -o nounset

############################
# Functions

usage() {
    declare invocation="$1"
    echo "Usage: $invocation
: <src> <dest> [-f|--force-new] [-b|--backup-count]" >&2
    echo "       $invocation
: -h|--help" >&2
    echo "" >&2
    echo "Used to create backups using hard links from previous backups to optimize" >&2
    echo "storage needs." >&2
    echo "" >&2
    echo "  src:                 Source path" >&2
    echo "  dest:                Destination path" >&2
    echo "  -b|--backup-count:   Number of backups to store before start to remove oldest" >&2
    echo "  -f|--force-new:      Force new backup sequence" >&2
}

err_exit() {
    declare msg="$1"
    declare invocation="$2"
    echo "${invocation}: ${msg}" >&2
    echo "" >&2
    usage ${invocation}
    exit 1
}

validate_dir() {
    declare dir="$1"
    [[ -d $dir ]]
}

get_absolute_path() {
    declare dir="$1"
    echo $(
        cd "${dir}"
        pwd -P
    )
}

############################
# Program

main() {
    invocation="$0"
    program="$(basename $invocation)"
    #datetime=$(date +%F-%H%M%S)

    arguments="${1:-NO_SOURCE_PATH}"
    destination_path="${2:-NO_DEST_PATH}"
    backupt_count="${3:-}"

    case "${arguments}" in
    --help | -h)
        usage ${invocation}
        exit 0
        ;;
    *) source_path="${arguments}" ;;
    esac

    if [ $# -lt 2 ]; then
        err_exit "Illegal number of argumentsuments" "${invocation}"
    fi

    echo "Executing using..."
    echo "Source path: ${source_path}"
    echo "Destination path: ${destination_path}"
    echo ""

    if validate_dir "$source_path"; then
        echo "found source dir"
        source_path=$(get_absolute_path "$source_path")
        echo "$source_path"
    fi

    if validate_dir "$destination_path"; then
        echo "found dest dir"
    fi

    return 0
}

main "$@"
