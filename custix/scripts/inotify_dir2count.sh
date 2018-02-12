#!/usr/bin/env ksh
. /etc/environment

IFS=":" DIRS=(${INOTIFY_DIRS})
for line in ${DIRS[*]}; do
    echo "${line}|`basename ${line}`"
done
