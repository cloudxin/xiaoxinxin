# !/bin/bash

if [ -f Makefile ]
then
    make
fi

scr="./chord"
if [ ! -x ${scr} ]
then
    echo "--- No executable chord found ---"
    exit 1
fi

sha=false
for h in sha1sum shasum
do
    hash $h 2>/dev/null
    if [ 0 -eq $? ]
    then
        sha=$h
        break
    fi
done

function test_one_hash {
    local inp=$1; shift
    local ftable=ftable500000.chord
    local actual=$(${scr} $ftable $inp | head -n 1 | awk '{print $1}')
    local expected=$(${sha} $inp | awk '{print $1}')

    if [ "x${expected}" != "x${actual}" ]
    then
        echo "--- Incorrect hash of $(cat $input2) ---"
        echo "    expected: ${expected}"
        echo "    received: ${actual}"
        exit 1
    fi
}

function test_hashing
{
    local input=myInput
    local input1=myInput4
    local input2=myInput5

    test_one_hash ${input}
    test_one_hash ${input1}
    test_one_hash ${input2}
    
    echo "+++ Correct hashes of input +++"
}

function test_forwardingalgo
{
    local ftable=$1
    local input=$2
    local expected=$3
    
    local actual=$(${scr} $ftable $input | tail -n 1)

    if [ "x${expected}" != "x${actual}" ]
    then
        echo "--- Incorrect forwarding ---"
        echo "    expected: ${expected}"
        echo "    received: ${actual}"
        exit 1
    fi
}

test_hashing
test_forwardingalgo ftable10 myInput2 1447ae1c6e16cce8e9d3b4e356e4aac14309a36a
test_forwardingalgo ftable10 myInput3 c529926345f602249ed53597152c6f580e2c101e
test_forwardingalgo ftable6k myInput4 4695b7850cb26a426e84eaa899811dd74f9ad0a4
test_forwardingalgo ftable6k myInput5 ca95bcb9245bebe56234d69200e5530b321d1ffa
test_forwardingalgo ftable50 myInput dd3a7458d527ba4d3a114e5f011f841ea5456718
test_forwardingalgo ftable50 myInput2 dd3a7458d527ba4d3a114e5f011f841ea5456718

