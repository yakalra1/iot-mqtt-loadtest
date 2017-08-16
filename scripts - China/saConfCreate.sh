#!/bin/bash
GATEWAY_FILE="/test/data/gateways"
#ORGID=${VCAP_SERVICES_IOTF_SERVICE_0_CREDENTIALS_ORG}
ORGID=${VCAP_SERVICES_USER_PROVIDED_0_CREDENTIALS_ORG}
MQTTHOST=${VCAP_SERVICES_USER_PROVIDED_0_CREDENTIALS_MQTTHOST}

declare -A gw_array
# read file line by line and populate the array. Field separator is "="
while IFS='=' read -r k v; do
   gw_array["$k"]="$v"
done < $GATEWAY_FILE

for ID in "${!gw_array[@]}"; do 
	TOKEN=${gw_array[$ID]}; 
done

touch /test/logs/brokerLog.log
chmod 777 /test/logs/brokerLog.log

#replace variables from template file with actual values
eval "cat <<EOF
$(</test/templates/sa.conf)
EOF
" 2> /dev/null > /test/conf/sa.conf