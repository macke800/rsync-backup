#!/bin/bash

############################
# Global variables

INVOCATION="$0"
ARG="${1:-NO_SOURCE_PATH}"
DEST_PATH="${2:-NO_DEST_PATH}"
BACKUP_COUNT="${3:-}"
DATETIME=$(date +%F-%H%M%S)
PROGRAM="$(basename $INVOCATION)"

############################
# Functions

usage() {
    echo "Usage: $INVOCATION: <src> <dest> [-f|--force-new] [-b|--backup-count]" >&2
    echo "       $INVOCATION: -h|--help" >&2
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
    MSG="$1"
    echo "$PROGRAM: $MSG" >&2
    echo "" >&2
    usage
    exit 1
}

validate_dir() {
    DIR="$1"
    [[ -d $DIR ]]
}

############################
# Program

case "$ARG" in
--help | -h)
    usage
    exit 0
    ;;
*) SOURCE_PATH="$ARG" ;;
esac

if [ $# -lt 2 ]; then
    err_exit "Illegal number of arguments"
fi

echo "Executing using..."
echo "Source path: $SOURCE_PATH"
echo "Destination path: $DEST_PATH"
echo ""

if validate_dir "$SOURCE_PATH"; then
    echo "found source dir"
fi

if validate_dir "$DEST_PATH"; then
    echo "found dest dir"
fi
