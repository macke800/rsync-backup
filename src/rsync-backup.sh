#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

MY_SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=./session.sh
. "${MY_SCRIPT_PATH}/session.sh"

############################
# Functions

usage() {
    declare invocation="$1"
    echo "Usage: $invocation    : [-b|--backup-count] [-r|--remote] <src> <dest>" >&2
    echo "       $invocation    : -h|--help" >&2
    echo "" >&2
    echo "Used to create backups using hard links from previous backups to optimize" >&2
    echo "storage needs." >&2
    echo "" >&2
    echo "  src:                 Source path" >&2
    echo "  dest:                Destination path" >&2
    echo "  -b|--backup-count:   Number of backups to store before start to remove oldest" >&2
    echo "  -r|--remote:         Destination directory on remote server, will use SSH" >&2
}

err_exit() {
    declare msg="$1"
    declare invocation="$2"
    echo "${invocation}: ${msg}" >&2
    echo "" >&2
    usage "${invocation}"
    exit 1
}

validate_dir() {
    declare dir="$1"
    [[ -d "${dir}" ]]
}

get_absolute_path() {
    declare dir="$1"
    echo "$(
        cd "${dir}"
        pwd -P
    )"
}

get_system_temp_dir() {
    dirname "$(mktemp -u)"
}

get_timestamp() {
    date +%F-%H%M%S
}

remote_execute() {
    declare hostname="$1"
    declare command="$2"
    ssh -f "${hostname}" "${command}"
}

############################
# Program

main() {
    declare invocation="$0"
    declare hostname=""
    declare max_backup_count=5

    while getopts "hr:b:" opt; do
        case "${opt}" in
        h)
            usage "${invocation}"
            exit 0
            ;;
        r)
            hostname="${OPTARG}"
            ;;
        b)
            max_backup_count="${OPTARG}"
            ;;
        *)
            exit 1
            ;;
        esac
    done
    shift $((OPTIND - 1))

    if ! [ $# -eq 2 ]; then
        err_exit "Illegal number of arguments" "${invocation}"
    fi

    declare source_path="$1"
    declare backup_root_path="$2"

    if validate_dir "${source_path}"; then
        source_path=$(get_absolute_path "$source_path")
    else
        err_exit "Source path not found!" "${invocation}"
    fi

    if [ -z "${hostname}" ]; then
        if validate_dir "${backup_root_path}"; then
            backup_root_path=$(get_absolute_path "${backup_root_path}")
        else
            err_exit "Destination path not found!" "${invocation}"
        fi
    fi

    echo "Source path: ${source_path}"
    echo "Backup(s) root path: ${backup_root_path}"

    declare new_session=true
    if is_session_active "${source_path}" "${backup_root_path}"; then
        echo "Session: Continue previous backup"
        new_session=false
    else
        echo "Session: New backup"
        create_session "${source_path}" "${backup_root_path}"
    fi

    declare rsync_args="-avh --safe-links --delete"
    declare -a backups
    if [ -z "${hostname}" ]; then
        mapfile -t backups < <(eval "find ${backup_root_path}/* -maxdepth 0 -type d -exec basename {} \\; 2>/dev/null | sort -r")
    else
        mapfile -t backups < <(remote_execute "${hostname}" "cd ${backup_root_path} && eval \"find ${backup_root_path}/* -maxdepth 0 -type d -exec basename {} \\; 2>/dev/null | sort -r\"")
        rsync_args="${rsync_args} -e ssh"
    fi

    # Check if we found a previous backup, this should be used as --link-dest argument to rsync
    if [ "$new_session" = true ]; then
        if [[ ${#backups[@]} -gt 0 ]]; then
            rsync_args="${rsync_args} --link-dest=../${backups[0]}"
        fi
        destination_path=${backup_root_path}/$(get_timestamp)
        if [ -z "${hostname}" ]; then
            mkdir "${destination_path}"
        else
            remote_execute "${hostname}" "mkdir ${destination_path}"
        fi
    else
        if [[ ${#backups[@]} -gt 1 ]]; then
            rsync_args="${rsync_args} --link-dest=../${backups[1]}"
        fi
        destination_path=${backup_root_path}/${backups[0]}
    fi

    # Used to manually test continue session feature, TODO: create automatic test case...
    #echo "--- sleep 5 ---"
    #sleep 5

    if ! [ -z "${hostname}" ]; then
        destination_path="${hostname}:${destination_path}"
    fi

    echo "Executing: rsync ${rsync_args[*]} ${source_path} ${destination_path}"
    eval "rsync ${rsync_args[*]} ${source_path} ${destination_path}"

    # Add one to include the current backup
    declare remove_count=$((${#backups[@]} + 1 - max_backup_count))
    if [ ${remove_count} -gt 0 ]; then
        # Create a sequence of array indexes for the entries to remove and itterate over those
        for i in $(seq $((${#backups[@]} - 1)) -1 $((${#backups[@]} - remove_count))); do
            if [ -z "${hostname}" ]; then
                echo "rm -rf "${backup_root_path:?}/${backups[${i}]:?}""
                rm -rf "${backup_root_path:?}/${backups[${i}]:?}"
            else
                remote_execute "${hostname}" "rm -rf ${backup_root_path:?}/${backups[${i}]:?}"
            fi
        done
    fi

    delete_session "${source_path}" "${backup_root_path}"

    # Remove backup if --backup-count is exeeded
    # Break out host tools
    return 0
}

main "$@"
