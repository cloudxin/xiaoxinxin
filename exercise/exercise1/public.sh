#! /bin/bash

submission_dir=$(pwd)
grading_dir=$(pwd)

cd ${submission_dir}

if [ -f Makefile ]
then
    make
fi

if [ ! -x cidr ]
then
    echo "--- No executable cidr found ---"
    exit 1
fi

function test_one {
    local input=$1
    local answer=$2
    local addr_only=$3
    echo ${input} > test_q1.inp
    local out=$(./cidr test_q1.inp)
    if [ "x${out}" != "x${answer}" ]
    then
        echo "--- Incorrect output for ${input} ---"
        echo "    expected: ${answer}"
        echo "    received: ${out}"
        exit 1
    fi
    echo "+++ Correct output ${out} for ${input} +++"
}

test_one 192.168.3.50/16 192.168.0.0/16 192.168.0.0
test_one 10.3.12.142/8 10.0.0.0/8 10.0.0.0
test_one 128.8.130.3/24 128.8.130.0/24 128.8.130.0 
test_one 172.26.5.86/23 172.26.4.0/23 172.26.4.0
test_one 104.199.122.13/14 104.196.0.0/14 104.196.0.0
test_one 205.132.0.201/22 205.132.0.0/22 205.132.0.0
test_one 104.25.96.103/12 104.16.0.0/12 104.16.0.0
test_one 23.227.38.32/19 23.227.32.0/19 23.227.32.0
test_one 69.163.179.233/17 69.163.128.0/17 69.163.128.0

