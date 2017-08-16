#!/bin/bash
echo "TEST_STATE=Deregistering" > /test/data/environment && source /test/data/environment
/test/scripts/bulkMasterRemove.sh
#echo "Displaying broker log"
#cat /test/logs/brokerLog.log
echo "TEST_STATE=Teardown" > /test/data/environment && source /test/data/environment
echo "end_time=$(date +%s%3N)" >> /test/logs/timelines.log
cat /test/logs/timelines.log
#TODO get data from cloudant historical about the count of messages, min, max and average latency of messages per device
#TODO upload all the logs and data file to object storage