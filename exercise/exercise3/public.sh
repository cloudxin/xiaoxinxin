#! /bin/bash

if [ -f Makefile ]
then
  make
fi

if [ ! -x icmp ]
then
  echo "--- No executable icmp found ---"
  exit 1
fi

if [ ! -f icmp.yml ]
then
  echo "--- No configuration file icmp.yml found ---"
  exit 1
fi

docker kill $(docker ps -q)
docker rm $(docker ps -aq)

# start the testbed
sudo mkdir -p /var/run/netns
sudo rm -f /var/run/netns/*
start_testbed.py -f icmp.yml

# make sure the nodes are named correctly
ip netns | grep test1
if [ $? -ne 0 ]
then
  echo "--- Did not create nodes test0 and test1 ---"
  exit 1
fi

# run the program, and capture results
capfile=test.cap
rm -f ${capfile}
sudo ip netns exec test1 sudo -u ${USER} \
    dumpcap -g -P -w ${capfile} -i test_1_0 -a duration:20 icmp &
cap_pid=$!
sudo ip netns exec test0 ./icmp
wait ${cap_pid}
stop_testbed.py -f icmp.yml

# check the results
echo_reply=$(tshark -r ${capfile} -Tfields -e ip.src -e ip.dst "ip.src == 186.192.0.0 and ip.dst == 186.192.0.1 and icmp.type == 0")
if [ "x${echo_reply}" == "x" ]
then
  echo "--- No ICMP echo reply found ---"
  exit 1
fi
echo "+++ ICMP echo reply found +++"

time_exceeded=$(tshark -r ${capfile} -Tfields -e ip.src -e ip.dst "ip.src == 186.192.0.0 and ip.dst == 186.192.0.1 and icmp.type == 11")
if [ "x${time_exceeded}" == "x" ]
then
  echo "--- No ICMP time exceeded found ---"
  exit 1
fi
echo ${time_exceeded} | grep ',' >/dev/null
if [ 0 -ne $? ]
then
  echo "--- No encapsulated IP header found for type 11 ---"
  exit 1
fi
echo "+++ ICMP time exceeded found +++"

dst_unreachable=$(tshark -r ${capfile} -Tfields -e ip.src -e ip.dst -e icmp.mtu "ip.src == 186.192.0.0 and ip.dst == 186.192.0.1 and icmp.type == 3 and icmp.code == 4")
if [ "x${dst_unreachable}" == "x" ]
then
  echo "--- No ICMP fragmentation required found ---"
  exit 1
fi
echo ${dst_unreachable} | grep ',' >/dev/null
if [ 0 -ne $? ]
then
  echo "--- No encapsulated IP header found for type 3 ---"
  exit 1
fi
mtu=$(( $(echo ${dst_unreachable} | awk '{print $3}') ))
if [ 0 -eq ${mtu} ]
then
  echo "--- No valid MTU found for type 3 ---"
  exit 1
fi
echo "+++ ICMP fragmentation required found +++"
