#!/bin/bash
NO_OF_DEVICES=${NUM_DPGW}
#ORGID=${VCAP_SERVICES_IOTF_SERVICE_0_CREDENTIALS_ORG}
#APIKEY=${VCAP_SERVICES_IOTF_SERVICE_0_CREDENTIALS_APIKEY}
#APITOKEN=${VCAP_SERVICES_IOTF_SERVICE_0_CREDENTIALS_APITOKEN}
MQTTHOST=${VCAP_SERVICES_USER_PROVIDED_0_CREDENTIALS_MQTTHOST}
APIKEY=${VCAP_SERVICES_USER_PROVIDED_0_CREDENTIALS_APIKEY}
APITOKEN=${VCAP_SERVICES_USER_PROVIDED_0_CREDENTIALS_APITOKEN}
ORGID=${VCAP_SERVICES_USER_PROVIDED_0_CREDENTIALS_ORG}
#echo "/test/scripts/bulkRemove.sh '${ORGID}' '${APIKEY}' '${APITOKEN}'"
eval "/test/scripts/bulkRemove.sh '${ORGID}' '${APIKEY}' '${APITOKEN}'"