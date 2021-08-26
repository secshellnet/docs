#!/bin/bash

# install curk if not already installed
if [ -z $(which curl) ]; then
    apt-get -y install curl
fi

# install jq if not already installed
if [ -z $(which jq) ]; then
    apt-get -y install jq
fi

# require environment variables
if [[ -z ${UPDATE_DNS} || -z ${CF_PROXIED} || -z ${CF_API_TOKEN} || -z ${DOMAIN} ]]; then
    echo "Missing environemnt variables, check docs!"
    exit 1
fi

record_name=${DOMAIN}
# strip subdomains from domain
zone_name=${record_name}
while [[ $(echo ${zone_name} | grep -o "\." | wc -l) -gt 1 ]]; do
    zone_name=${zone_name#*.}
done

# get dns zone
zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${zone_name}&status=active" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

# get dns record for configured domain
raw_records=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=AAAA,A&name=${record_name}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" | jq -r '{"result"}[]')

# check if host has an ipv6 address
ipv6_addr=$(curl -s -6 ifconfig.io);

# check if host has an ipv4 address
ipv4_addr=$(curl -s -4 ifconfig.io)

records_ids=$(echo ${raw_records} | jq -r '.[].id')
for record_id in ${records_ids}; do
    record=$(echo ${raw_records} | jq -r '.[] |select(.id=="'${record_id}'")')

    # record does exist
    old_record_content=$(echo ${record} | jq -r '.content')
    record_type=$(echo ${record} | jq -r '.type')

    case ${record_type} in
        'AAAA')
            [ -n ${ipv6_addr} ] && record_content=${ipv6_addr}
            ;;
        'A')
            [ -n ${ipv4_addr} ] && record_content=${ipv4_addr}
            ;;
        *)
            echo "[DNS] Unsupported record type!"
            ;;
    esac


    if [ "${old_record_content}" != "${record_content}" ]; then
        if [ ${UPDATE_DNS} -eq 1 ]; then
            read -p "[DNS] Updating: ${record_name}=${addr} (current: ${old_record_content}) (Type: YES): " confirm
            if [ "${confirm}" == "YES" ]; then
                # update dns record
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo ${record} | jq -r '.id')" \
                    -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" \
                    --data '{"type":"'${record_type}'","name":"'${record_name}'","content":"'${record_content}'","ttl":1,"proxied":'${CF_PROXIED}'}' | jq
                echo "[DNS] Update was successful"
            fi
        else
            echo "[DNS] Invalid record for ${record_name} (is ${old_record_content} but should be ${record_content})"
        fi
    else
        echo "[DNS] Ok"
    fi
done

# dns record does not eixst
if [ -z "${records_ids}" ]; then
    if [ ${UPDATE_DNS} -eq 1 ]; then
        [ -n ${ipv6_addr} ] && record_content=${ipv6_addr} record_type='aaaa'
        [ -n ${ipv4_addr} ] && record_content=${ipv4_addr} record_type='a'

        read -p "[DNS] Create: ${record_name}=${record_content} (Type: YES): " confirm
        if [ "${confirm}" == "YES" ]; then
            # create dns record
            curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
                -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" \
                --data '{"type":"'${record_type}'","name":"'${record_name}'","content":"'${record_content}'","ttl":1,"proxied":'${CF_PROXIED}'}' | jq
            echo "[DNS] Update was successful"
        fi
    else
        echo "[DNS] Missing record for ${record_name}"
    fi
fi
