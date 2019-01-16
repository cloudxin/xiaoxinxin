#! /bin/bash

submission_dir=$(pwd)
grading_dir=$(pwd)

cd ${submission_dir}

submission_script="./dns"

if [ ! -x ${submission_script} ]
then
    echo "--- No executable dns found ---"
    exit 1
fi

function test_one {
    target=$1; shift
    server=$1; shift
    truth=$*
    capfile="test_${target}.pcap"
    dumpcap -i any -a duration:10 -w ${capfile} &
    dumpcap_pid=$!
    out=$(sudo timeout 10s ${submission_script} -a ${target} -n ${server} 2>/dev/null)
    got_a=""
    num_recs=0
    IFS=$'\n'
    for l in $out
    do
	num_recs=$(( ${num_recs} + 1 ))
	q=$(echo $l | cut -d' ' -f1)
	t=$(echo $l | cut -d' ' -f2)
	v=$(echo $l | cut -d' ' -f3)
	if [ "$t" == "1" ]
	then
	    got_a="${got_a} $v"
	fi
    done
    unset IFS

    if [ ${num_recs} < 4 ]
    then
	echo "--- Did not print intermediate records ---"
        exit 1
    fi

    for g in ${got_a}
    do
	for a in ${truth}
	do
	    if [ "$a" == "$g" ]
	    then
		echo "+++ Got a valid A record for ${target} +++"
		break 2
	    fi
	done
    done
    wait ${dumpcap_pid}
    itrpktcap=$(tshark -r ${capfile} -T fields -e dns.flags.recdesired -e dns.qry.type -e dns.qry.name -e ip.dst "dns.qry.name==${target} and dns.flags.response==0 and dns.flags.recdesired==0")
    recpktcap=$(tshark -r ${capfile} -T fields -e dns.flags.recdesired -e dns.qry.type -e dns.qry.name -e ip.dst "dns.qry.name==${target} and dns.flags.response==0 and dns.flags.recdesired==1")
    if [ "x" == "x${itrpktcap}" ]
    then
        echo "--- Did not perform iterative query ---"
        exit 1
    fi
    if [ "x" != "x${recpktcap}" ]
    then
        echo "--- Performed recursive query ---"
        exit 1
    fi
    echo "+++ Correctly performed query for ${target} +++"
}

test_one www.cs.umd.edu 199.7.91.13 128.8.127.4
test_one www.whitehouse.gov 192.58.128.30 23.196.56.110
test_one www.espn.com 192.5.5.241 34.239.92.167 35.168.187.154 34.194.75.200

