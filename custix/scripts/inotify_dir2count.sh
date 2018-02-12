#!/usr/bin/env ksh

IFS=":" DIRS=(${INOTIFY_DIRS})
for line in ${DIRS[*]}; do
    echo "${line}|`basename ${line}`"
done
