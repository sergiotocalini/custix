#!/usr/bin/env ksh

type=${1}

OS_VENDOR=`uname -s`
if [[ ${OS_VENDOR} == 'Linux' ]]; then
    regex="(Not Specified|Not Present)"
    if [[ ${type} == 'chassis' ]]; then
	data[0]=`dmidecode -s system-manufacturer`
	data[1]=`dmidecode -s system-product-name`
	data[2]=`dmidecode -s system-serial-number`
	data[3]=`dmidecode -s chassis-type`
	for index in ${!data[@]}; do
	    data[${index}]=`echo "${data[${index}]}" | sed -E "s:${regex}::g"`
	done
	res=`printf "%s " "${data[@]}"`
    elif [[ ${type} == 'type' ]]; then
	data=`dmidecode -s system-manufacturer`
	if [[ ${data} =~ (QEMU|VMware.*) ]]; then
	    res='Virtual'
	else
	    res='Physical'
	fi
    elif [[ ${type} == 'model' ]]; then
	res=`dmidecode -t system | grep "SKU Number:" | awk -F ':' '{print $2}' | awk '{$1=$1};1'`
    elif [[ ${type} == 'vendor' ]]; then
	res=`dmidecode -s system-manufacturer`
    elif [[ ${type} == 'serial' ]]; then
	res=`dmidecode -s system-serial-number`
    elif [[ ${type} == 'arch' ]]; then
	res=`arch`
    fi
fi

echo ${res:-0}
exit ${rcode:-0}
