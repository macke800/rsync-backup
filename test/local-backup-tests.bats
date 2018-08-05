load ../../test/test_helper/bats-support/load
load ../../bats-assert/load
load ./test_helper

function setup() {
    mkdir -p "$destination_path"
}

function teardown() {
    rm -rf "$destination_path"
}

@test "Local backup with existing source and destination shall work" {
    run $BATS_TEST_DIRNAME/../src/rsync-backup.sh $test_data_path $BATS_TEST_DIRNAME/destination
    assert_success

    # Check that there is only one backup
    assert_equal $(ls -1 $BATS_TEST_DIRNAME/destination/* | wc -l)  "1"

    # Check that the existing backup is the exact source
    assert $(diff -rq $test_data_path $destination_path/*/test-data)
}

@test "Local backup with non existing source path shall fail" {
    run $BATS_TEST_DIRNAME/../src/rsync-backup.sh ./non_existing_path $destination_path
    assert_failure
    assert_output --partial "Source path not found!"
}

@test "Local backup with non existing destination path shall fail" {
    run $BATS_TEST_DIRNAME/../src/rsync-backup.sh $test_data_path ./non_existing_path 
    assert_failure
    assert_output --partial "Destination path not found!"
}

@test "Local backup successfully uses hard links" {
    # Several backups shall not consume more disk space
    run $BATS_TEST_DIRNAME/../src/rsync-backup.sh $test_data_path $destination_path
    assert_success
    sleep 1
    size_one_backup=$(du -sh $destination_path | sed -E 's/([1-9]+)M.*/\1/')
    run $BATS_TEST_DIRNAME/../src/rsync-backup.sh $test_data_path $destination_path
    assert_success
    size_two_backups=$(du -sh $destination_path | sed -E 's/([1-9]+)M.*/\1/')
    assert_equal $size_two_backups $size_one_backup
}
