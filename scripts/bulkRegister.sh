#!/bin/bash
GATEWAY_FILE="/test/data/gateways"
DEVICE_FILE="/test/data/devices"

GATEWAY_REG_LOG="/test/logs/gateway_reg.log"
DEVICE_REG_LOG="/test/logs/device_reg.log"

DEVICE_EVENT=${DEV_EVT}
INDEX=$5

# Remove if file exists else create an empty file
cat /dev/null > $GATEWAY_REG_LOG
cat /dev/null > $DEVICE_REG_LOG
cat /dev/null > $GATEWAY_FILE
cat /dev/null > $DEVICE_FILE

# Gateway and Device type is expected to be created manually before executing the scripts

if [ -z "$INDEX" ]; then
	GATEWAY_ID="$(uuidgen -r)"
else
	GATEWAY_ID="${INDEX}"
fi

GATEWAY_AUTHTOKEN=$(uuidgen -r)
GATEWAY_JSON="[{\"typeId\": \"mosquitto-gateway\",\"deviceId\": \"$GATEWAY_ID\",\"authToken\": \"$GATEWAY_AUTHTOKEN\"}]"
echo "$GATEWAY_ID=$GATEWAY_AUTHTOKEN" >> $GATEWAY_FILE

#echo "curl -s --user '$2':'$3' 'https://$1.internetofthings.chinabluemix.net/api/v0002/bulk/devices/add' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$GATEWAY_JSON' --compressed"
#eval "curl -s --user '$2':'$3' 'https://$1.internetofthings.ibmcloud.com/api/v0002/bulk/devices/add' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$GATEWAY_JSON' --compressed" >> $GATEWAY_REG_LOG
eval "curl -s --user '$2':'$3' 'https://$1.internetofthings.chinabluemix.net/api/v0002/bulk/devices/add' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$GATEWAY_JSON' --compressed" >> $GATEWAY_REG_LOG

IFS=',' read -r -a array <<< "${DEVICE_EVENT}"
length=${#array[@]}

DEVICE_JSON="["
for ((i=1;i<=$4;i++)); 
do
	index=$(shuf -i 0-`expr $length - 1` -n 1)
	#echo "index $index"
	devevtstr=${array[index]}
	#echo "devevtstr $devevtstr"
	
	IFS=':' read -r -a devevtarr <<< "$devevtstr"
	DEVICETYPE=${devevtarr[0]}
	#echo "DEVICETYPE $DEVICETYPE"
	
	if [ -z "$INDEX" ]; then
		DEVICE_ID="$(uuidgen -r)"
	else
		DEVICE_ID="$(( ( $INDEX -1 ) * $4 + $i ))"
	fi

	DEVICE_AUTHTOKEN=$(uuidgen -r)
	if [[ $i -eq `expr $4` ]]; then
		DEVICE_JSON="$DEVICE_JSON{\"typeId\": \"$DEVICETYPE\",\"deviceId\": \"$DEVICE_ID\",\"authToken\": \"$DEVICE_AUTHTOKEN\"}]"
	else
		DEVICE_JSON="$DEVICE_JSON{\"typeId\": \"$DEVICETYPE\",\"deviceId\": \"$DEVICE_ID\",\"authToken\": \"$DEVICE_AUTHTOKEN\"},"
	fi
	echo "$DEVICE_ID=$DEVICE_AUTHTOKEN,$DEVICETYPE" >> $DEVICE_FILE
done

#echo "curl -s --user '$2':'$3' 'https://$1/api/v0002/bulk/devices/add' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$DEVICE_JSON' --compressed"
#eval "curl -s --user '$2':'$3' 'https://$1.internetofthings.ibmcloud.com/api/v0002/bulk/devices/add' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$DEVICE_JSON' --compressed" >> $DEVICE_REG_LOG
eval "curl -s --user '$2':'$3' 'https://$1.internetofthings.chinabluemix.net/api/v0002/bulk/devices/add' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Connection: keep-alive' --data-binary '$DEVICE_JSON' --compressed" >> $DEVICE_REG_LOG
#read response and retry for registrations that failed.