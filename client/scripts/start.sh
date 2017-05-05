#!/bin/bash
source $(dirname "$0")/utils.sh

VAR_FILE="/test-client/data/vars.properties"
LOG_FILE="/test-client/logs/out.log"
cat /dev/null > $LOG_FILE

#set variables from file
init_var

#check cf login is active
cflogin_status=$(cf apps | grep "OK" )

if [[ -z $cflogin_status ]]; then
	# Accept inputs from user for logging into Bluemix and IBM Containers
	notnull_string "Enter API Endpoint:" API
	
	notnull_string "Enter Bluemix Id:" USER
	
	notnull_password "Enter Bluemix Password:" PWD
	
	notnull_string "Enter Bluemix Org:" ORG
	
	notnull_string "Enter Bluemix Space:" SPACE
	
	cf api ${API} >> /test-client/logs/out.log 2>&1
	RESULT=$?
	if [ $RESULT -ne 0 ]; then
	        echo "Error setting api ${API}"
	        exit 1
	else
	        echo "Successfully set API Endpoint"
	fi
	
	cf auth ${USER} ${PWD} >> $LOG_FILE 2>&1
	RESULT=$?
	if [ $RESULT -ne 0 ]; then
	        echo "Error logging into Bluemix with ID ${USER}"
	        exit 1
	else
	        echo "Successfully logged into Bluemix"
	fi
	
	cf target -o ${ORG} -s ${SPACE} >> /test-client/logs/out.log 2>&1
	RESULT=$?
	if [ $RESULT -ne 0 ]; then
	        echo "Error setting target: org ${ORG} and space ${SPACE}"
	        exit 1
	else
	        echo "Successfully set target"
	fi
fi

cf ic login >> /test-client/logs/out.log 2>&1
RESULT=$?
if [ $RESULT -ne 0 ]; then
	echo "Error logging into IBM Containers"
	exit 1
else
	echo "Successfully logged into IBM Containers"
fi

# Accept inputs from user for loadtest

notnull_int "Enter Number of Gateways(integer only):" "Number of Gateways must be an integer" NUM_GW

notnull_int "Enter Number of Devices per Gateway(integer only):" "Number of Devices per Gateway must be an integer" NUM_DPGW

notnull_int "Enter Number of Device Publications(integer only):" "Number of Device Publications must be an integer" NUM_PUB

notnull_int "Enter Sleep Time between Device Publications(integer only):" "Sleep Time between Device Publications must be an integer" SLEEP_PUB

notnull_int "Enter Sleep Time between Devices(integer only):" "Sleep Time between Devices must be an integer" SLEEP_BT_DEV

notnull_string "Enter Device Type and Event in form \"DeviceType=EventType\" for e.g Demo:status where Demo is DeviceType and status is EventType \
\nFor multiple combinations Enter \"DeviceType:EventType1,DeviceType:EventType1,DeviceType1:EventType2\"" DEVICE_EVENT

null_yn "Use UUID for Device Id  (y/n):" USE_UUID

notnull_string "Enter IMAGE NAME:" IMAGE_NAME

notnull_string "Enter APP NAME:" BIND_TO_APP

memory_msg="Select Memory Size:(1-9)\n\t1. Pico: 64 MB Memory, 4GB Storage\n\t2. Nano: 128 MB Memory, 8GB Storage \
\n\t3. Micro: 256 MB Memory, 16GB Storage \n\t4. Tiny: 512 MB Memory, 32GB Storage \
\n\t5. Small: 1GB Memory, 64GB Storage\n\t6. Medium: 2 GB Memory, 128GB Storage\n\t7. Large: 4 GB Memory, 256GB Storage \
\n\t8. X-Large: 8 GB Memory, 512GB Storage\n\t9. 2X-Large: 16 GB Memory, 1TB Storage"

memory_errmsg="Select one of the option (1-9)"
notnull_int "$memory_msg"  "$memory_errmsg" MEMORY_SIZE

#check if MEMORY_SIZE is within acceptable values
while true; do
    if [[ $MEMORY_SIZE -gt 0 && $MEMORY_SIZE -lt 10 ]]; then
        break
    else
        echo "Memory Size is not within limit."
        unset MEMORY_SIZE
        notnull_int "$memory_msg"  "$memory_errmsg" MEMORY_SIZE
    fi
done

cat /dev/null >$VAR_FILE
echo "API=$API" >> $VAR_FILE
echo "USER=$USER" >> $VAR_FILE
echo "ORG=$ORG" >> $VAR_FILE
echo "SPACE=$SPACE" >> $VAR_FILE
echo "DEVICE_EVENT=$DEVICE_EVENT" >> $VAR_FILE
echo "IMAGE_NAME=$IMAGE_NAME" >> $VAR_FILE
echo "BIND_TO_APP=$BIND_TO_APP" >> $VAR_FILE
		
ARGS="-e BIND_TO_APP=${BIND_TO_APP} -e NUM_GW=${NUM_GW} -e NUM_DPGW=${NUM_DPGW} -e NUM_PUB=${NUM_PUB} -e SLEEP_PUB=${SLEEP_PUB} -e SLEEP_BT_DEV=${SLEEP_BT_DEV} \
-e IMAGE_NAME=${IMAGE_NAME} -e DEVICE_EVENT=${DEVICE_EVENT} -e MEMORY_SIZE=${MEMORY_SIZE} -e USE_UUID=${USE_UUID}"

echo "Running test harness in background. Use \"tail -f /test-client/logs/out.log\" for progress"
nohup $(dirname "$0")/loadtest_controller.sh $ARGS >> /test-client/logs/out.log &