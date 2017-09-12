#!/bin/bash
ORGID=${VCAP_SERVICES_IOTF_SERVICE_0_CREDENTIALS_ORG}
DEVICEID=$1
DEVICETYPE=$2
EVENTTYPE=$3
topic="iot-2/type/kce_dtu/id/$DEVICEID/evt/$EVENTTYPE/fmt/json"

#payload template file name <DeviceType>_<Eventtype>.payload 
#for e.g Demo_status.payload where Demo is DeviceType and status is Eventtype
PAYLOAD_NAME="/test/templates/${DEVICETYPE}_${EVENTTYPE}.payload"
if [ ! -f $PAYLOAD_NAME ] || [ ! -s $PAYLOAD_NAME ]; then
        echo "Payload template file ${PAYLOAD_NAME} does not exists or is empty"
        exit 1
fi

i=1
clientID="g:$ORGID:$DEVICETYPE:$DEVICEID"

while [[ $i -le $NUM_PUB ]]; do
    #current date in millis
    NOW_MS=$(date +%s%3N);
    #current date in UTC
    NOW_DT=$(date -u +"%Y-%m-%dT%TZ");
    
    #replace variables in payload template with values
    #do not format the below 3 lines
    payload=$(eval "cat <<EOF
    $(<$PAYLOAD_NAME)
    " 2> /dev/null)
    payload=${payload/EQNUM/$DEVICEID}
    #echo "$1 publishing to topic $topic at $NOW_DT"
    #echo "mosquitto_pub -t $topic -m '$payload' -i $clientID && sleep $SLEEP_PUB"
    eval "mosquitto_pub -t $topic -m '$payload' -q 1 -i $clientID && sleep $SLEEP_PUB"
    (( i++ ));
done