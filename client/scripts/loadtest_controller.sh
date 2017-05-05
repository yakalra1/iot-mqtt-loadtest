#!/bin/bash

# function for checking state of container
#arguments - container name file, state
check_and_wait_for_state() {
	local CHECK_STATE=$1
	local CONTAINER_PENDING="container_pending"
	local CONTAINER_PENDING_TMP="container_pending.tmp"
	echo "started checking and waiting for ${CHECK_STATE}"
	cat /dev/null > ${CONTAINER_PENDING}
	cat /dev/null > ${CONTAINER_PENDING_TMP}

	# wait for status of containers to become Running
	cat ${CONTAINER_FILE} > ${CONTAINER_PENDING}
	local overall_status=true
	local counter=0
	while ${overall_status}; do
		while IFS='' read -r line || [[ -n "$line" ]]; do
			local STATE=$(cf ic inspect $line | grep "Status" | awk '{print $2}' | sed 's/"//g') 
			#echo "$line is in $state state"
			#assuming the container started will be in running state as containers are start with tail command
			if [ "${STATE}" != "${CHECK_STATE}" ]; then
				echo ${line} >> ${CONTAINER_PENDING_TMP}
			fi
		done < ${CONTAINER_PENDING}
		let counter=counter+1
		# check if containers are still not running
		if [ -s ${CONTAINER_PENDING_TMP} ]; then
			#move the contents of tmp to pending file and clear the tmp
			cat /dev/null > $CONTAINER_PENDING
			cat $CONTAINER_PENDING_TMP > $CONTAINER_PENDING
			cat /dev/null > $CONTAINER_PENDING_TMP
		else
			overall_status=false
			return 0
		fi

		# to prevent script to go into infinite loop
		if [[ ( $counter -gt 100 ) ]]; then
			overall_status=false
			return 1
		fi
		sleep 2
	done
}

show_container_status() {
	local state
	while IFS='' read -r line || [[ -n "$line" ]]; do
		state=$(cf ic inspect $line | grep "Status" | awk '{print $2}' | sed 's/"//g') 
		#echo "$line is in $state"
	done < $CONTAINER_FILE
}

validate_env_var() {
	echo ${as_array[$1]}
}

check_and_wait_for_harness_status(){
	local CHECK_STATE=$1
	local max_counter=$2
	local CONTAINER_PENDING="container_pending"
	local CONTAINER_PENDING_TMP="container_pending.tmp"

	cat /dev/null > $CONTAINER_PENDING
	cat /dev/null > $CONTAINER_PENDING_TMP

	# wait for status of containers to become Running
	cat ${CONTAINER_FILE} > ${CONTAINER_PENDING}
	local overall_status=true
	local counter=0
	local state_change_status
	local state
	#keep the max_counter matching the number of publications
	if [ -z "$max_counter" ]; then
		max_counter=100
	fi
	
	while $overall_status; do
		state_change_status=false
		while IFS='' read -r line || [[ -n "$line" ]]; do
			state=$(cf ic exec $line /test/scripts/checkTestState.sh)
			RESULT=$?
			if [ $RESULT -eq 0 ]; then
				#assuming the container started will be in running state as containers are start with tail command
				if [ "$state" != "$CHECK_STATE" ]; then
					echo $line >> $CONTAINER_PENDING_TMP
				else
					echo "$line is in $state test state"
					state_change_status=true
				fi
			fi
		done < $CONTAINER_PENDING
		
		let counter=counter+1
		#swap contents only if state is changed
		if  $state_change_status; then
			# check if containers are still not running
			if [ -s $CONTAINER_PENDING_TMP ]; then
				#move the contents of tmp to pending file and clear the tmp
				cat /dev/null > $CONTAINER_PENDING
				cat $CONTAINER_PENDING_TMP > $CONTAINER_PENDING
				cat /dev/null > $CONTAINER_PENDING_TMP
			else
				overall_status=false
				return 0
			fi
		fi

		# to prevent script to go into infinite loop
		#keep larger count for broker to complete the processing
		if [[ ( $counter -gt $max_counter ) ]]; then
			overall_status=false
			return 1
		fi
		sleep 5
	done
}

startup() {
if $USE_UUID; then
	while IFS='' read -r line || [[ -n "$line" ]]; do
		#setup each container in background
		cf ic exec -d $line /test/scripts/setup.sh
	done < $CONTAINER_FILE

else
	local counter=1
	while IFS='' read -r line || [[ -n "$line" ]]; do
		#setup each container in background
		cf ic exec -d $line /test/scripts/setup.sh $counter
		(( counter++ ));
	done < $CONTAINER_FILE
fi
}

start_attack() {
while IFS='' read -r line || [[ -n "$line" ]]; do
	#start Attack for each container in background
	cf ic exec -d $line /test/scripts/startAttack.sh
done < $CONTAINER_FILE
}

teardown() {
while IFS='' read -r line || [[ -n "$line" ]]; do
	#teardown each container in background
	cf ic exec -d $line /test/scripts/teardown.sh
done < $CONTAINER_FILE
}

restart_containers() {
while IFS='' read -r line || [[ -n "$line" ]]; do
	cf ic restart $line
done < $CONTAINER_FILE
}

stop_remove_containers() {
	echo "Stopping all container"
	while IFS='' read -r line || [[ -n "$line" ]]; do
		# stop containers
		#echo "Stopping container $line"
		cf ic stop $line
	done < $CONTAINER_FILE
	#check if containers are in Shutdown state, wait till all the containers are running
	check_and_wait_for_state "Shutdown"
	local RESULT=$?
	if [ $RESULT -ne 0 ]; then
		echo "Some containers did not stop within expected time limit"
	fi
	echo "Removing all container"
	while IFS='' read -r line || [[ -n "$line" ]]; do
		#remove containers
		#echo "Removing container $line"
		cf ic rm $line
	done < $CONTAINER_FILE
}

#script execution starts here
while [[ $# -gt 1 ]]
do
key="$1"
#array containing all the passed optional arguments
declare -A as_array

case $key in
    -e|--env)
        keyval="$2"
        tmp_arr=(${keyval//=/ })
        as_array["${tmp_arr[0]}"]=${tmp_arr[1]}
        shift # past argument
        ;;
    *)
    # unknown option
    ;;
esac
shift # past argument or value
done

# initialize container name file
CONTAINER_FILE="container_names"
cat /dev/null > $CONTAINER_FILE

#validate all the environment variables

#validate number of gateways env
NUM_GW=$(validate_env_var "NUM_GW")
if [ -z $NUM_GW ]; then
	echo "Number of Gateways not specified, exiting..."
	exit 1
fi

#validate number of Devices per gateway env
NUM_DPGW=$(validate_env_var "NUM_DPGW")
if [ -z $NUM_DPGW ]; then
	echo "Number of Devices per Gateway not specified, exiting..."
	exit 1
fi

#validate number of Device publications env
NUM_PUB=$(validate_env_var "NUM_PUB")
if [ -z $NUM_PUB ]; then
	echo "Warning: Number of Device publications not specified, default to 5"
	NUM_PUB=5
fi

#validate sleep time between publications env
SLEEP_PUB=$(validate_env_var "SLEEP_PUB")
if [ -z $SLEEP_PUB ]; then
	echo "Warning: Sleep time between publications not specified, defaulting to 1 sec"
	SLEEP_PUB=1
fi

#validate sleep time between devices env
SLEEP_BT_DEV=$(validate_env_var "SLEEP_BT_DEV")
if [ -z $SLEEP_BT_DEV ]; then
	echo "Warning: Sleep time between devices not specified, defaulting to 1 sec"
	SLEEP_BT_DEV=1
fi

#validate use UUID
USE_UUID=$(validate_env_var "USE_UUID")
if [ -z $USE_UUID ]; then
	echo "Device Id generated will be a sequence of integers"
	USE_UUID=false
fi

#validate sleep time between devices env
DEVICE_EVENT=$(validate_env_var "DEVICE_EVENT")
if [ -z $DEVICE_EVENT ]; then
	echo "Device Type and Event Type mapping not specified, exiting..."
	exit 1
fi

#validate memory size for each container
MEMORY_SIZE=$(validate_env_var "MEMORY_SIZE")
if [ -z $MEMORY_SIZE ]; then
	echo "Memory size not set, using default memory Micro: 256 MB Memory, 16GB Storage"
	MEMORY_SIZE=3
fi


#validate bind app env
CCS_BIND_APP=$(validate_env_var "BIND_TO_APP")
if [ ! -z ${CCS_BIND_APP} ]; then
    APP=$(cf env ${CCS_BIND_APP})
    APP_FOUND=$?
    if [ $APP_FOUND -ne 0 ]; then
    	echo "${CCS_BIND_APP} application not found in space.  Please confirm that you wish to bind the container to the application, \
    	and that the application exists"
        exit 1
	fi
    VCAP_SERVICES=$(echo "${APP}" | grep "VCAP_SERVICES")
    SERVICES_BOUND=$?
    if [ $SERVICES_BOUND -ne 0 ]; then
    	echo "No services appear to be bound to ${CCS_BIND_APP}.  Please confirm that you have bound the intended services to the application."
        exit 1
    fi
else
	echo "CCS_BIND_APP environment variable not found"
	exit 1
fi

#validate Image
#check if image_name variable is set
if [ -z $IMAGE_NAME ]; then
	#check if IMAGE_NAME as argument to the script
	IMAGE_NAME=$(validate_env_var "IMAGE_NAME")
	if [ -z $IMAGE_NAME ]; then
	echo "IMAGE_NAME variable not specified, must be complete image name with repository and TAG"
	exit 1
	fi
fi

RESULT=$(cf ic inspect ${IMAGE_NAME} | grep "\"Id\":" | awk '{print $2}')
if [ -z $RESULT ]; then
	echo "Could not find image $IMAGE_NAME"
	exit 1
else
	echo "Found image ${IMAGE_NAME}"
fi

ARGS="-e CCS_BIND_APP=${CCS_BIND_APP} -e NUM_DPGW=${NUM_DPGW} -e NUM_PUB=${NUM_PUB} -e SLEEP_PUB=${SLEEP_PUB} -e SLEEP_BT_DEV=${SLEEP_BT_DEV} \
-e DEV_EVT=${DEVICE_EVENT}"
containers=0

#set memory args as per the selection
case $MEMORY_SIZE in
1)
 MEMORY_ARGS="-m 64"
  ;;
2)
 MEMORY_ARGS="-m 128"
  ;;
3)
 MEMORY_ARGS="-m 256"
  ;;
4)
 MEMORY_ARGS="-m 512"
  ;;
5)
 MEMORY_ARGS="-m 1024"
  ;;
6)
 MEMORY_ARGS="-m 2048"
  ;;
7)
 MEMORY_ARGS="-m 4096"
  ;;
8)
 MEMORY_ARGS="-m 8192"
  ;;
9)
 MEMORY_ARGS="-m 16384"
  ;;
*)
 MEMORY_ARGS="-m 256"
  ;;
esac

echo "Load Test Started at $(date +%s%3N)"
echo "container_rampup_starttime=$(date +%s%3N)"
for ((i=1;i<=$NUM_GW;i++)); do
	rm -rf container_id.cid
	cf ic run --cidfile container_id.cid -p 22:22 -p 1883:1883 ${MEMORY_ARGS} ${ARGS} ${IMAGE_NAME} tail -f /dev/null
	RESULT=$?
	if [ $RESULT -ne 0 ]; then
		if [[ containers -gt 0 ]]; then
			echo "Some containers are already running, cleaning up.."
			stop_remove_containers
		fi
		echo "Error starting containers, exiting..."
		exit 1
	else
		awk '{print}' container_id.cid >> $CONTAINER_FILE
		(( containers++ ));
	fi
done

sleep 5

#check if containers are in running state, wait till all the containers are running
check_and_wait_for_state "Running"
RESULT=$?
if [ $RESULT -ne 0 ]; then
	echo "Some containers did not run within expected time limit"
else
	echo "All containers are running"
fi

echo "container_rampup_endtime=$(date +%s%3N)"

startup

#sleep for container to complete initial part of startup
sleep 2

# check if all containers are in ready state for attack
echo "Checking if all the container have Registered"
check_and_wait_for_harness_status "Registered"

# start the attack
echo "Execute start attack script on all containers"
echo "container_attack_starttime=$(date +%s%3N)"
start_attack

#sleep till container completes attack 
sleep $(( $NUM_PUB * $SLEEP_PUB ))

# check if all containers have attacked
echo "Checking if all the container have completed Attack"
check_and_wait_for_harness_status "Attacked" $NUM_PUB

echo "container_attack_endtime=$(date +%s%3N)"

#sleep before tear down
#sleep 60

#tear down the containers
echo "Tearing down all the container"
teardown

# check if all containers have been teardown
echo "Checking if all the containers have been Teardown"
check_and_wait_for_harness_status "Teardown"

#checking for logs of all containers
#echo "Checking for logs of all the containers"
#while IFS='' read -r line || [[ -n "$line" ]]; do
#	cf ic logs $line
#done < $CONTAINER_FILE

#stop and remove containers
stop_remove_containers

echo "Load Test Completed at $(date +%s%3N)"