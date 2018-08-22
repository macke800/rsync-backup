#!/usr/bin/env bash

# shellcheck source=./md5.sh
. "${MY_SCRIPT_PATH}/md5.sh"

get_session_filename() {
    declare source_path="$1"
    declare backup_root_path="$2"
    echo "$(get_system_temp_dir)/rsync-$(md5_from_string "${source_path}${backup_root_path}")"
}

create_session() {
    declare source_path="$1"
    declare backup_root_path="$2"
    declare session_file
    session_file="$(get_session_filename "${source_path}" "${backup_root_path}")"
    echo "session_started=$(get_timestamp)" >"${session_file}"
}

is_session_active() {
    declare source_path="$1"
    declare backup_root_path="$2"
    declare session_file
    session_file="$(get_session_filename "${source_path}" "${backup_root_path}")"
    [[ -f "${session_file}" ]]
}

delete_session() {
    declare source_path="$1"
    declare backup_root_path="$2"
    declare session_file
    session_file="$(get_session_filename "${source_path}" "${backup_root_path}")"
    rm "${session_file}"
}
