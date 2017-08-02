#!/bin/bash
GATEWAY_FILE="/test/data/gateways"
DEVICE_FILE="/test/data/devices"

GATEWAY_DEREG_LOG="/test/logs/gateway_dereg.log"
DEVICE_DEREG_LOG="/test/logs/device_dereg.log"

DEVICE_EVENT=${DEV_EVT}

#Construct message for gateway
while IFS='=' read -r id pwd; do
    	GATEWAY_JSON="[{\"typeId\": \"mosquitto-gateway\",\"deviceId\": \"$id\"}]"
done <$GATEWAY_FILE

#Remove gateway
echo "Removing gateway device"
#echo "curl-s --user '$2':'$3' 'https://$1.internetofthings.ibmcloud.com/api/v0002/bulk/devices/remove' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$GATEWAY_JSON' --compressed"
#eval "curl -s --user '$2':'$3' 'https://$1.internetofthings.ibmcloud.com/api/v0002/bulk/devices/remove' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$GATEWAY_JSON' --compressed" >> $GATEWAY_DEREG_LOG
eval "curl -s --user '$2':'$3' 'https://$1.internetofthings.chinabluemix.net/api/v0002/bulk/devices/remove' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$GATEWAY_JSON' --compressed" >> $GATEWAY_DEREG_LOG

#Construct message for devices
DEVICE_JSON="["

last=$(<$DEVICE_FILE wc -l)
counter=1
while IFS='=' read -r id pwddevtype; do

	IFS=',' read -r -a pwddevtype_arr <<< "$pwddevtype"
	deviceType=${pwddevtype_arr[1]}

    if [[ $counter -eq $last ]]; then
		DEVICE_JSON="$DEVICE_JSON{\"typeId\": \"$deviceType\",\"deviceId\": \"$id\"}]"
    else
    	DEVICE_JSON="$DEVICE_JSON{\"typeId\": \"$deviceType\",\"deviceId\": \"$id\"},"
    fi
	counter=$counter+1
done <$DEVICE_FILE

#Remove devices
echo "Removing devices"
#echo "curl -s --user '$2':'$3' 'https://$1.internetofthings.ibmcloud.com/api/v0002/bulk/devices/remove' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$DEVICE_JSON' --compressed"
#eval "curl -s --user '$2':'$3' 'https://$1.internetofthings.ibmcloud.com/api/v0002/bulk/devices/remove' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$DEVICE_JSON' --compressed" >> $DEVICE_DEREG_LOG
eval "curl -s --user '$2':'$3' 'https://$1.internetofthings.chinabluemix.net/api/v0002/bulk/devices/remove' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$DEVICE_JSON' --compressed" >> $DEVICE_DEREG_LOG
#read response and retry for deregistrations that failed.

DTU_DEVICE_JSON="["

last=$(<$DEVICE_FILE wc -l)
counter=1
while IFS='=' read -r id pwddevtype; do

    IFS=',' read -r -a pwddevtype_arr <<< "$pwddevtype"
    deviceType=${pwddevtype_arr[1]}

    if [[ $counter -eq $last ]]; then
        DTU_DEVICE_JSON="$DTU_DEVICE_JSON{\"typeId\": \"lce_dtu\",\"deviceId\": \"$id\"}]"
    else
        DTU_DEVICE_JSON="$DTU_DEVICE_JSON{\"typeId\": \"lce_dtu\",\"deviceId\": \"$id\"},"
    fi
    counter=$counter+1
done <$DEVICE_FILE

#Remove devices
echo "Removing devices"
#echo "curl -s --user '$2':'$3' 'https://$1.internetofthings.ibmcloud.com/api/v0002/bulk/devices/remove' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$DTU_DEVICE_JSON' --compressed"
#eval "curl -s --user '$2':'$3' 'https://$1.internetofthings.ibmcloud.com/api/v0002/bulk/devices/remove' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$DTU_DEVICE_JSON' --compressed" >> $DEVICE_DEREG_LOG
eval "curl -s --user '$2':'$3' 'https://$1.internetofthings.chinabluemix.net/api/v0002/bulk/devices/remove' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$DTU_DEVICE_JSON' --compressed" >> $DEVICE_DEREG_LOG

