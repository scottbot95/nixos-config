#!/usr/bin/env bash

set -x

DATA_DIR=/var/lib/dns-updater
IP_FILE=$DATA_DIR/last-known-ip

checkVarFile() {
    local file="${!1}"
    if [[ -z "$file" ]]; then
        echo "\$$1 is not set" 
        exit 1
    fi

    if [[ ! -f "$file" ]]; then
        echo "File '$file' does not exist"
        exit 2
    fi
}

namesilo_api() {
    checkVarFile "NAMESILO_KEY_FILE"

    NAMESERVER=$1; shift
    IP=$1; shift

    API_KEY=$(cat "$NAMESILO_KEY_FILE")
    
    curl --silent --show-error --fail-with-body \
        --location --request GET \
        "https://www.namesilo.com/api/modifyRegisteredNameServer?version=1&type=xml&key=$API_KEY&domain=faultymuse.com&current_host=$NAMESERVER&new_host=$NAMESERVER&ip1=$IP"

    return
}

pdns_api() {
    checkVarFile "PDNS_KEY_FILE"

    VERB="$1"; shift
    API_PATH="$1"; shift
    BODY="$1"; shift

    curl --silent --show-error --fail-with-body \
        --location --request "$VERB" \
        "http://127.0.0.1:8081/api/v1/servers/localhost$API_PATH" \
        -H "X-API-Key: $(cat "$PDNS_KEY_FILE")" \
        --data-raw "$BODY" \
        "$@"
    
    return
}

update_records() {( set -e # fail instantly on any failure here
    local ip="$1"

    pdns_api PATCH /zones/faultymuse.com. "{
        \"rrsets\": [
            {
                \"name\": \"us-west-1.faultymuse.com.\",
                \"type\": \"A\",
                \"ttl\": 3600,
                \"changetype\": \"REPLACE\",
                \"records\": [
                    {
                        \"content\": \"$ip\",
                        \"disabled\": false
                    }
                ]
            }
        ]
    }"
    echo "us-west-1.faultymuse.com updated successfully"

    namesilo_api ns1 "$ip"
    namesilo_api ns2 "$ip"

    echo "Updated NameSilo glue records"

    echo -n "$ip" > $IP_FILE
)}

main() {( set -e
    mkdir -p $DATA_DIR

    # poll current public IP
    curr_ip=$(curl 'https://api.ipify.org' 2>/dev/null)
    old_ip=$(2>/dev/null cat $IP_FILE || echo "unknown")

    # If previous known IP doesn't match
    if [[ "$old_ip" != "$curr_ip" ]]; then
        echo "Public IP changed, updating DNS. New IP: $curr_ip Old IP: $old_ip"
        update_records "$curr_ip"
        if [ $? != 0 ]; then
            >&2 echo "Failed to update dns"
        fi
    fi
)}

main
