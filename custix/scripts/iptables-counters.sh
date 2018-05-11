#!/usr/bin/env ksh
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(dirname $0)
SCRIPT_CACHE=${SCRIPT_DIR}/tmp/${SCRIPT_NAME%.*}
SCRIPT_CACHE_TTL=1
TIMESTAMP=`date '+%s'`

method=${1}
profile=${2}
source=${3}
property=${4}

zabbix_not_support() {
    echo "ZBX_NOTSUPPORTED"
    exit 1
}

get_configfile() {
    resource=${1:-all}

    JSON_DIR="${SCRIPT_DIR}/${SCRIPT_NAME%.*}.d"
    if [[ ${resource} != 'all' ]]; then
       for configfile in ${JSON_DIR}/*.json; do
          name=`jq -r 'select(.name=="'${resource}'")|.name' ${configfile} 2>/dev/null`
          if [[ ${name} == ${resource} ]]; then
             res=${configfile}
             break
          fi
       done
    else
       count=0
       for configfile in ${JSON_DIR}/*.json; do
          res[${count}]=${configfile}
          let "count=count+1"
       done
    fi
    echo "${res[@]:-0}"
    return 0
}

refresh_cache() {
    resource=${1}

    config_json=$(get_configfile ${resource})
    [ ${config_json} == 0 ] && zabbix_not_support

    [[ -d ${SCRIPT_CACHE} ]] || mkdir -p ${SCRIPT_CACHE}
    file=${SCRIPT_CACHE}/${resource}.json
    if [[ $(( `stat -c '%Y' "${file}" 2>/dev/null`+60*${SCRIPT_CACHE_TTL} )) -le ${TIMESTAMP} ]]; then
        json_raw="{ \"name\": \"${resource}\", \"sources\": {}}"

	iptables_data=`sudo iptables-save -c | grep -v -- "\[0:0\]"`
        filters=`jq -r '.filters[]' ${config_json} 2>/dev/null`
        while read rule; do
           iptables_data=`echo "${iptables_data}" | grep -- "${rule}"`
        done <<< "${filters}"
        
        while read line; do
           source=`echo "${line}" | awk '{print $5}'`
           packages=`echo "${line}" | awk '{print $1}' | awk -F: '{print $1}' | sed 's/\[//g'`
           bytes=`echo "${line}" | awk '{print $1}' | awk -F: '{print $2}' | sed 's/\]//g'`
           stats_data="{}"
           stats_data=`echo "${stats_data}" | jq -c '.packages="'${packages}'"'`
           stats_data=`echo "${stats_data}" | jq -c '.bytes="'${bytes}'"'`
           json_raw=`echo "${json_raw}" | jq -c '.sources+={"'${source}'":'"${stats_data}"'}'`
        done <<< "${iptables_data}"

        echo "${json_raw}" | jq . 2>/dev/null > ${file}
    fi
    echo "${file}"
}

if [[ ${method} == "stats" ]]; then
    stats_json=$(refresh_cache ${profile})
    [ ${?} != 0 ] && zabbix_not_support

    if ! [[ ${source} =~ (^[[:blank:]]*$|full|all) ]]; then
        attr="sources.\"${source}\""
        if ! [[ ${property} =~ (^[[:blank:]]*$|full|all) ]]; then
            attr+=".${property/all/}"
        fi
    fi
    res=`jq -r ".${attr/full/}" ${stats_json}`
    echo "${res:-0}"
elif [[ ${method} == "sources" ]]; then
    for configfile in $(get_configfile); do
        profile=`jq -r '.name' ${configfile} 2>/dev/null`
        stats_json=$(refresh_cache ${profile})
        [ ${?} != 0 ] && zabbix_not_support

        for src in `jq -r '.sources|keys[]' ${stats_json} 2>/dev/null`; do
            echo "${profile}|${src}"
        done
    done
fi

exit ${rcode:-0}
