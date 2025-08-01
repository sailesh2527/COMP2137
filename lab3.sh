#!/bin/bash

VERBOSE=""
if [[ "$1" == "-verbose" ]]; then
  VERBOSE="-verbose"
fi

# Use actual IPs assigned to the containers
scp configure-host.sh remoteadmin@server1:/root
ssh remoteadmin@server1 "/root/configure-host.sh $VERBOSE -name loghost -ip 192.168.16.241 -hostentry webhost 192.168.16.242"

scp configure-host.sh remoteadmin@server2:/root
ssh remoteadmin@server2 "/root/configure-host.sh $VERBOSE -name webhost -ip 192.168.16.242 -hostentry loghost 192.168.16.241"

./configure-host.sh $VERBOSE -hostentry loghost 192.168.16.241
./configure-host.sh $VERBOSE -hostentry webhost 192.168.16.242

