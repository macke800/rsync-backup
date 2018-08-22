#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

md5_from_string() {
    declare string="$1"
    declare md5
    if command -v md5sum >/dev/null; then
        md5="md5sum"
    else
        md5="md5"
    fi
    echo "${string}" | ${md5} | sed -E 's/(^[a-f|0-9])*.$/\1/'
}
