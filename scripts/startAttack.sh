#!/bin/bash

DEVICE_FILE="/test/data/devices"
pid_file="pid_file"

DEVICE_EVENT=${DEV_EVT}

#convert the device-event type to array from string
IFS=',' read -r -a array <<< "${DEVICE_EVENT}"
length=${#array[@]}

#convert array to map with devicetype as key and event array as value.
declare -A devTypeMap

for ((i=0;i<$length;i++)); do
    devevnt=${array[$i]}
    #extract device type and event type from sring
    IFS=':' read -r -a devevnt_arr <<< "$devevnt"
    devtype=${devevnt_arr[0]}
    evttype=${devevnt_arr[1]}
    #check if devicetype is present in map
    if [ ! ${devTypeMap[$devtype]} ]; then
    	devTypeMap[$devtype]=$evttype
    else
    	#else add value to current value separated by comma
    	tmp=${devTypeMap[$devtype]}
        devTypeMap[$devtype]="$tmp,$evttype"
    fi
done

echo "TEST_STATE=Attacking" > /test/data/environment && source /test/data/environment
/test/scripts/saConfCreate.sh

#start the gateway broker
mosquitto -c /test/conf/sa.conf &
broker_pid=$!
sleep 10;

eval "mosquitto_sub -C $(( $NUM_PUB * $SLEEP_PUB ))  -v -t iot-2/type/+/id/+/evt/+/fmt/json >> /test/logs/brokerPublishReceive.log" &
sub_pid=$!

#log all publish status messages of the broker
#mosquitto_sub -v -t \$SYS/broker/publish/messages/# >> /test/logs/brokerStatus.log &

#clear the file if it exists, otherwise create an empty file
cat /dev/null > $pid_file


echo "publish_starttime=$(date +%s%3N)" >> /test/logs/timelines.log
#start the devices
equipment_number = 0
while IFS='=' read -r id pwddevtype; do
    let equipment_number=equipment_number + 1
	sleep $SLEEP_BT_DEV; 
	
	# pass deviceid devicetype and eventtype to devicePublisher.sh
	
	IFS=',' read -r -a pwddevtype_arr <<< "$pwddevtype"
	token=${pwddevtype_arr[0]}
	deviceType=${pwddevtype_arr[1]}

	#randomly pickup the events for the devicetype to sent
	#get array of eventtype for a devicetype
	
	#randomly select an event if there are multiple
	eventTypes=${devTypeMap[$deviceType]}
	IFS=',' read -r -a evtType_arr <<< "$eventTypes"
	evtlen=${#evtType_arr[@]}
	index=$(shuf -i 0-`expr $evtlen - 1` -n 1)
	eventType=${evtType_arr[index]}	
	#echo "/test/scripts/devicePublisher.sh $id ${deviceType} ${eventType} &"
	/test/scripts/devicePublisher.sh $id ${deviceType} ${eventType} $equipment_number &
	
	pid=$!
	echo $pid >> $pid_file
	#echo "Device publisher running with pid $pid"
done <$DEVICE_FILE

while true; do
    if [ -s pid_file ] ; then
        for pid in `cat pid_file`
        do
            #echo "Checking the $pid"
            kill -0 "$pid" 2>/dev/null || sed -i "/^$pid$/d" pid_file
        done
    else
        echo "All the publishers have completed publishing events"
        echo "publish_endtime=$(date +%s%3N)" >> /test/logs/timelines.log
        break
    fi
    sleep 2
done

#wait for subscriber to exit, it would mean all the messages are published by the broker
wait $sub_pid

#log all publish status messages of the broker
#mosquitto_sub -v -t \$SYS/broker/publish/messages/# >> /test/logs/brokerStatus.log &

#allow broker to flush messages in buffer.
sleep 5
#stop the broker
kill -9 $broker_pid

echo "TEST_STATE=Attacked" > /test/data/environment && source /test/data/environment