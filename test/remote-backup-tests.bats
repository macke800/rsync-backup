#!/usr/bin/env bats

load ./test_helper

remote_destination="/home/testuser/destination"

function setup() {
    mkdir -p "${remote_destination}"
}

function teardown() {
    rm -rf "${remote_destination}"
}

@test "Remote backup with existing source and destination shall work" {
    run $BATS_TEST_DIRNAME/../src/rsync-backup.sh -r testuser@localhost ${test_data_path} ${remote_destination}
    assert_success

    # Check that there is only one backup
    assert_equal $(ls -1 "${remote_destination}" | wc -l)  "1"

    # Check that the existing backup is the exact source
    assert $(diff -rq ${test_data_path} "${remote_destination}/*/test-data")
}

@test "Remote backup successfully uses hard links" {
    # Several backups shall not consume more disk space
    run $BATS_TEST_DIRNAME/../src/rsync-backup.sh -r testuser@localhost ${test_data_path} ${remote_destination}
    assert_success
    sleep 1
    size_one_backup=$(du -sh ${remote_destination} | sed -E 's/([1-9]+)M.*/\1/')
    run $BATS_TEST_DIRNAME/../src/rsync-backup.sh -r testuser@localhost ${test_data_path} ${remote_destination}
    assert_success
    size_two_backups=$(du -sh ${remote_destination} | sed -E 's/([1-9]+)M.*/\1/')
    assert_equal $size_two_backups $size_one_backup
}

