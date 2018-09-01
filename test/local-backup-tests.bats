#!/usr/bin/env bats

load ./test_helper

function setup() {
    mkdir -p "${destination_path}"
}

function teardown() {
    rm -rf "${destination_path}"
}

@test "Local backup with existing source and destination shall work" {
    run ${BATS_TEST_DIRNAME}/../src/rsync-backup.sh ${test_data_path} ${BATS_TEST_DIRNAME}/destination
    assert_success

    # Check that there is only one backup
    assert_equal $(ls -1 "${BATS_TEST_DIRNAME}/destination" | wc -l)  "1"

    # Check that the existing backup is the exact source
    assert $(diff -rq ${test_data_path} ${destination_path}/*/test-data)
}

@test "Local backup with non existing source path shall fail" {
    run ${BATS_TEST_DIRNAME}/../src/rsync-backup.sh ./non_existing_path ${destination_path}
    assert_failure
    assert_output --partial "Source path not found!"
}

@test "Local backup with non existing destination path shall fail" {
    run ${BATS_TEST_DIRNAME}/../src/rsync-backup.sh ${test_data_path} ./non_existing_path 
    assert_failure
    assert_output --partial "Destination path not found!"
}

@test "Local backup successfully uses hard links" {
    # Several backups shall not consume more disk space
    run ${BATS_TEST_DIRNAME}/../src/rsync-backup.sh ${test_data_path} ${destination_path}
    assert_success
    sleep 1
    size_one_backup=$(du -sh ${destination_path} | sed -E 's/([1-9]+)M.*/\1/')
    run ${BATS_TEST_DIRNAME}/../src/rsync-backup.sh ${test_data_path} ${destination_path}
    assert_success
    size_two_backups=$(du -sh ${destination_path} | sed -E 's/([1-9]+)M.*/\1/')
    assert_equal $size_two_backups $size_one_backup
}

@test "Local backup if -b2, check that cleanup is done accordingly and only the two latest backups remain" {
    run ${BATS_TEST_DIRNAME}/../src/rsync-backup.sh -b 2 ${test_data_path} ${destination_path}
    assert_success
    declare -a after_first_backup
    mapfile -t after_first_backup < <(eval "find ${destination_path}/* -maxdepth 0 -type d -exec basename {} \\; 2>/dev/null | sort")
    assert_equal ${#after_first_backup[@]} 1
    
    sleep 1
    run ${BATS_TEST_DIRNAME}/../src/rsync-backup.sh -b 2 ${test_data_path} ${destination_path}
    assert_success
    declare -a after_second_backup
    mapfile -t after_second_backup < <(eval "find ${destination_path}/* -maxdepth 0 -type d -exec basename {} \\; 2>/dev/null | sort")
    assert_equal ${#after_second_backup[@]} 2
    assert_equal ${after_first_backup[0]} ${after_second_backup[0]}

    sleep 1
    run ${BATS_TEST_DIRNAME}/../src/rsync-backup.sh -b 2 ${test_data_path} ${destination_path}
    assert_success
    declare -a after_third_backup
    mapfile -t after_third_backup < <(eval "find ${destination_path}/* -maxdepth 0 -type d -exec basename {} \\; 2>/dev/null | sort")
    assert_equal ${#after_third_backup[@]} 2
    [ "${after_third_backup[0]}" != "${after_first_backup[0]}" ]
    [ "${after_second_backup[1]}" = "${after_third_backup[0]}" ]

}

# TODO:
# - Test with paths containing spaces