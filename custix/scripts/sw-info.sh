#!/usr/bin/env ksh
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(dirname $0)
SCRIPT_CACHE=${SCRIPT_DIR}/tmp
SCRIPT_CACHE_TTL=5
TIMESTAMP=`date '+%s'`

resource=${1:-full}
property=${2}

refresh_cache() {
    [[ -d ${SCRIPT_CACHE} ]] || mkdir -p ${SCRIPT_CACHE}
    file=${SCRIPT_CACHE}/${SCRIPT_NAME%.*}.json
    if [[ $(( `stat -c '%Y' "${file}" 2>/dev/null`+60*${SCRIPT_CACHE_TTL} )) -le ${TIMESTAMP} ]]; then
        IFS=":" APPS=(${AMANA_APPS})
        for app in ${APPS[@]}; do
            if [[ ${app} == 'springboot' ]]; then
		springboot=`/etc/init.d/spring-boot list json id name desc version 2>/dev/null`
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.springboot=${springboot}" 2>/dev/null`
	    elif [[ ${app} == 'gunicorn' ]]; then
		gunicorn=`/etc/init.d/gunicorn list json id name desc version 2>/dev/null`
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.gunicorn=${gunicorn}" 2>/dev/null`
            elif [[ ${app} == 'mysql' ]]; then
		dbs=`/etc/zabbix/scripts/agentd/mysbix/mysbix.sh -s db_count 2>/dev/null`
		version=`/etc/zabbix/scripts/agentd/mysbix/mysbix.sh -s version 2>/dev/null`
		mysql="{\"version\": \"${version}\", \"databases\": ${dbs}}"
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.mysql=${mysql}" 2>/dev/null`
	    elif [[ ${app} == 'arango' ]]; then
		version=`/etc/zabbix/scripts/agentd/mysbix/mysbix.sh -s api-version -a p=version 2>/dev/null`
		license=`/etc/zabbix/scripts/agentd/mysbix/mysbix.sh -s api-version -a p=license 2>/dev/null`
		arango="{\"version\": \"${version}\", \"license\": \"${license}\"}"
            fi
        done
	json_keys=()
	for key in ${json_keys[@]}; do
            eval value=\${$key}
	    json_raw=`echo "${json_raw:-{}}" | jq ".${key}=\"${value}\"" 2>/dev/null`
	done
        echo "${json_raw}" | jq . 2>/dev/null > ${file}
    fi
    echo "${file}"
}
json=$(refresh_cache)
res=`jq -r ".${resource/full/}" ${json}`

echo "${res:-0}"
exit ${rcode:-0}
