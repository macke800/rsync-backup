# rsync-backup - A backup rotating shell script

The goals of rsync-backup are

- To be able to easily backup a source path tree to multiple snapshots on destination.

- Support destinations running over SSH.

- Thanks to rsync's --link-dest feature not need more space for each snapshot.

## Table of Contents

- [How to use](#how-to-use)

## How to use

```
Usage: src/rsync-backup.sh    : [-b NUM] [-r USER@SERVER] [-p PORT] <src> <dest>
       src/rsync-backup.sh    : -h|--help

Used to create backups using hard links from previous backups to optimize
storage needs.

  src:    Source path
  dest:   Destination path
  -b:     Number of backups to store before start to remove oldest
  -r:     Destination directory on remote server, will use SSH
  -p:     Set non-standard SSH port if -r is used
```

### Examples

Local backup (maybe to NFS share) with 10 snapshots:
```
rsync-backup -b10 ./src /mnt/backup/target
```

Remote backup with 5 snapshots and alternative SSH port 2222:
```
rsync-backup -b5 -r user@server.com -p2222 ./src /home/user/target
```

## How to build debian package

Build the debian package:
```
make clean
make package
```
Package will be in `build`-folder.

## Known limitations (things to fix)

- Destination path for remote backup need to be absolute
