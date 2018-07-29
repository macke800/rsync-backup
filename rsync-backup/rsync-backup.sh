#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

############################
# Functions

usage() {
    declare invocation="$1"
    echo "Usage: $invocation    : [-f|--force-new] [-b|--backup-count] [-r|--remote] <src> <dest>" >&2
    echo "       $invocation    : -h|--help" >&2
    echo "" >&2
    echo "Used to create backups using hard links from previous backups to optimize" >&2
    echo "storage needs." >&2
    echo "" >&2
    echo "  src:                 Source path" >&2
    echo "  dest:                Destination path" >&2
    echo "  -b|--backup-count:   Number of backups to store before start to remove oldest" >&2
    echo "  -f|--force-new:      Force new backup sequence" >&2
    echo "  -r|--remote:         Destination directory on remote server, will use SSH" >&2
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
    [[ -d "${dir}" ]]
}

get_absolute_path() {
    declare dir="$1"
    echo $(
        cd "${dir}"
        pwd -P
    )
}

get_system_temp_dir() {
    echo $(dirname $(mktemp -u))
}

md5_from_paths() {
    declare source_path="$1"
    declare destination_path="$2"

    echo $(echo "src: ${source_path} dst: ${destination_path}" | md5sum | sed -E 's/(^[a-f|0-9])*.$/\1/')
}

get_timestamp() {
    echo $(date +%F-%H%M%S)
}

get_session_filename() {
    declare source_path="$1"
    declare destination_path="$2"
    echo "$(get_system_temp_dir)/rsync-$(md5_from_paths ${source_path} ${destination_path})"
}

create_session() {
    declare source_path="$1"
    declare destination_path="$2"
    declare session_file="$(get_session_filename ${source_path} ${destination_path})"
    echo "session_started=$(get_timestamp)" >"${session_file}"
}

is_session_active() {
    declare source_path="$1"
    declare destination_path="$2"
    declare session_file="$(get_session_filename ${source_path} ${destination_path})"
    [[ -f "${session_file}" ]]
}

delete_session() {
    declare source_path="$1"
    declare destination_path="$2"
    declare session_file="$(get_session_filename ${source_path} ${destination_path})"
    rm ${session_file}
}

remote_execute() {
    declare hostname="$1"
    declare command="$2"
    echo $(ssh -f "${hostname}" "${command}")
}

############################
# Program

main() {
    declare invocation="$0"
    declare hostname=""

    while getopts "hr:" opt; do
        case "${opt}" in
        h)
            usage ${invocation}
            exit 0
            ;;
        r)
            declare hostname=${OPTARG}
            ;;
        esac
    done
    shift $((OPTIND - 1))

    if ! [ $# -eq 2 ]; then
        err_exit "Illegal number of arguments" "${invocation}"
    fi

    declare source_path="$1"
    declare destination_path="$2"

    if validate_dir "${source_path}"; then
        source_path=$(get_absolute_path "$source_path")
    else
        err_exit "Source path not found!" "${invocation}"
    fi

    if [ -z ${hostname} ]; then
        if validate_dir "${destination_path}"; then
            destination_path=$(get_absolute_path "${destination_path}")
        else
            err_exit "Destination path not found!" "${invocation}"
        fi
    fi

    echo "Source path: ${source_path}"
    echo "Destination path: ${destination_path}"
    echo ""

    declare is_session_new=true
    if is_session_active "${source_path}" "${destination_path}"; then
        echo "Continuing session..."
        is_session_new=false
    else
        echo "Starting new session..."
        create_session "${source_path}" "${destination_path}"
    fi

    declare rsync_args="-avh --safe-links --delete"
    if [ -z ${hostname} ]; then
        declare -a backups=($(ls -1 "${destination_path}" | sort -r))
    else
        declare backups=($(remote_execute "${hostname}" "cd ${destination_path} && ls -1 | sort -r"))
        rsync_args="${rsync_args} -e ssh"
    fi

    # Check if we found a previous backup, this should be used as --link-dest argument to rsync
    if [[ ${#backups[@]} -gt 0 && is_session_new ]]; then
        rsync_args="${rsync_args} --link-dest=../${backups[0]}"
    fi

    echo "${rsync_args}"
    # If session file exists use its data
    # If session file does not exist, extract latest backup to use as --link-desc folder
    # rsync -avh -e ssh --safe-links --delete --link-dest=../backup-four ./source pi@git.webmalmgren.lan:~/backup-test/backup-five
    #echo "${#backups[@]}"

    # Remove backup if --backup-count is exeeded

    return 0
}

main "$@"
