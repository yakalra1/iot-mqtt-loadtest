#!/bin/bash
echo "TEST_STATE=Starting" > /test/data/environment && source /test/data/environment
/test/scripts/bulkMasterRegister.sh $1
echo "TEST_STATE=Registered" > /test/data/environment && source /test/data/environment