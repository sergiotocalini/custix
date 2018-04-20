#!/usr/bin/env ksh
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(dirname $0)
SCRIPT_CACHE=${SCRIPT_DIR}/tmp
SCRIPT_CACHE_TTL=10
TIMESTAMP=`date '+%s'`

resource=${1}
property=${2}

refresh_cache() {
    [[ -d ${SCRIPT_CACHE} ]] || mkdir -p ${SCRIPT_CACHE}
    file=${SCRIPT_CACHE}/${SCRIPT_NAME%.*}.json
    if [[ $(( `stat -c '%Y' "${file}" 2>/dev/null`+60*${SCRIPT_CACHE_TTL} )) -le ${TIMESTAMP} ]]; then
	regex="(Not Specified|Not Present)"
	dmi=`dmidecode`
	dmi_system=`echo "${dmi}" | sed '/System Information/, /Handle.*/!d'`
	dmi_chassis=`echo "${dmi}" | sed '/Chassis Information/, /Handle.*/!d'`

	vendor=`echo "${dmi_system}"|grep "Manufacturer:"|awk '{print $2}'|awk '{$1=$1};1'`
	sku=`echo "${dmi_system}"|grep "SKU Number:"|awk -F ':' '{print $2}'|awk '{$1=$1};1'`
	serial=`echo "${dmi_system}"|grep "Serial Number:"|awk -F ':' '{print $2}'|awk '{$1=$1};1'`
	model=`echo "${dmi_system}"|grep "Product Name:"|awk -F ':' '{print $2}'|awk '{$1=$1};1'`
	arch=`arch`
	chassis_type=`echo "${dmi_chassis}"|grep "Type:"|awk '{print $2}'|awk '{$1=$1};1'`
	if [[ ${vendor} =~ (QEMU|VMware.*) ]]; then
            type='Virtual'
	else
            type='Physical'
	fi
	chassis[0]=${vendor}
        chassis[1]=${model}
        chassis[2]=${serial}
        chassis[3]=${chassis_type}
        for index in ${!chassis[@]}; do
            chassis[${index}]=`echo "${chassis[${index}]}" | sed -E "s:${regex}::g"`
        done
        chassis=`printf "%s " "${chassis[@]}"`
	blockdevices=`lsblk -d -ibo NAME,SIZE,VENDOR,SUBSYSTEMS,SERIAL -J | jq .blockdevices`
	json_keys=('vendor' 'type' 'blockdevices' 'model' 'sku' 'chassis' 'serial' 'arch')
	for key in ${json_keys[@]}; do
	    jq -c ".${key}='${${key}}'" ${file}
	done
    fi
    echo "${file}"
}
json=$(refresh_cache)
res=`jq ".${resource/full/}" ${json}`

echo ${res:-0}
exit ${rcode:-0}
