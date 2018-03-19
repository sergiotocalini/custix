#!/usr/bin/env ksh

type=${1}

OS_VENDOR=`uname -s`
if [[ ${OS_VENDOR} == 'Linux' ]]; then
    res=`lsb_release -s -d 2>/dev/null`
fi

echo ${res:-0}
exit ${rcode:-0}
