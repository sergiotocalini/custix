#!/usr/bin/env ksh

type=${1}

OS_FAMILY=`lsb_release -i -s`
if [[ ${OS_FAMILY} =~ (Ubuntu|Debian) ]]; then
    if [[ ${type} == "security" ]]; then
	res=`apt-get -s upgrade | grep -ci ^inst.*security | tr -d '\n'`
    elif [[ ${type} == "updates" ]]; then
	res=`apt-get -s upgrade | grep -iPc '^Inst((?!security).)*$' | tr -d '\n'`
    fi
fi

echo ${res:-0}
exit ${rcode:-0}
