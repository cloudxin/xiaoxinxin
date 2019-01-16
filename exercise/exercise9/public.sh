#! /bin/bash

if [ -f Makefile ]
then
    make
fi

if [ ! -x serial ]
then
    echo "--- No executable serial found ---"
    exit 1
fi

function has_opcode {
    local opcode=$1
    local fname=$2
    echo -en "\x0${opcode}" | cmp -n 1 ${fname} >/dev/null 2>&1
    return $?
}

function test_zero {
    local out=$(./serial test_out.bin 0)
    has_opcode 0 test_out.bin
    if [ 0 -ne $? ]
    then
        echo "--- Opcode 0 does not start with byte 0x00 ---"
        exit 1
    fi
    local test_len=$(wc -c test_out.bin | awk '{print $1}')
    if [ 1 -ne ${test_len} ]
    then
        echo "--- Opcode 0 is wrong length ---"
        echo "    expected: 1"
        echo "    received: ${test_len}"
        exit 1
    fi
    echo "+++ Opcode 0 correctly encoded +++"
}

function u16 {
    echo $1 | awk '{printf("%04x",$n)}' | xxd -r -p
}

function u32 {
    echo $1 | awk '{printf("%08x",$n)}' | xxd -r -p
}

function test_one {
    local nints=$#
    local out=$(./serial test_out.bin 1 $@)

    local correct_length=$(( 1 + 2 + 4*${nints} ))

    has_opcode 1 test_out.bin
    local binary_opcode=$?
    if [ 0 -ne ${binary_opcode} ]
    then
        echo "--- Opcode 1 does not start with byte 0x01 ---"
        exit 1
    fi

    local contents_length=$(wc -c test_out.bin | awk '{print $1}')
    if [ ${contents_length} -ne ${correct_length} ]
    then
        echo "--- Opcode 1 has wrong length ---"
        echo "    expected: ${correct_length}"
        echo "    received: ${contents_length}"
        exit 1
    fi

    # Test length of list
    local byte_order_good=1
    u16 ${nints} | cmp -i 1:0 -n 2 test_out.bin >/dev/null 2>&1
    local test_lsize_n=$?
    if [ 0 -ne ${test_lsize_n} ]
    then
        echo "--- Incorrect list length ---"
        exit 1
    fi

    # Test integers (isize)
    local offset=3
    local good_ints=0
    while [ $# -gt 0 ]
    do
        local current_num=$1; shift

        u32 ${current_num} | cmp -i ${offset}:0 -n 4 test_out.bin >/dev/null 2>&1
        local test_n=$?
        if [ 0 -ne ${test_n} ]
        then
            echo "--- Incorrect encoding ---"
            exit 1
        fi

        offset=$(( ${offset} + 4 ))
    done
    echo "+++ Opcode 1 correctly encoded +++"
}

function test_two {
    local s=$1
    local out=$(./serial test_out.bin 2 "$s")
    local correct_length=$(( 1 + 2 + ${#s} ))

    has_opcode 2 test_out.bin
    local binary_opcode=$?
    if [ 0 -ne ${binary_opcode} ]
    then
        echo "--- Opcode 2 does not start with byte 0x02 ---"
        exit 1
    fi
    local test_length=$(dd if=test_out.bin bs=1 count=2)
    echo ${test_length} | grep -E '^[0-9a-fA-F]+$' >/dev/null 2>&1
    if [ 0 -eq $? ]
    then
        echo "--- Opcode 2 encoding is not binary ---"
        exit 1
    fi

    local contents_length=$(wc -c test_out.bin | awk '{print $1}')
    if [ ${contents_length} -ne ${correct_length} ]
    then
        echo "--- Opcode 2 has wrong length ---"
        echo "    expected: ${correct_length}"
        echo "    received: ${contents_length}"
        exit 1
    fi

    # Test length of string (lsize)
    local correct_str_len_hex=$(u16 ${#s} | xxd -p)
    u16 ${#s} | cmp -i 1:0 -n 2 test_out.bin >/dev/null 2>&1
    local test_lsize_n=$?
    if [ 0 -ne ${test_lsize_n} ]
    then
        echo "--- Incorrect string length ---"
        echo "    expected: ${correct_str_len_hex}"
        echo "    received: $(dd if=test_out.bin bs=1 count=2 skip=1 2>/dev/null|xxd -p)"
        exit 1
    fi
    echo "+++ Opcode 2 correctly encoded +++"
}

test_zero

test_one 12 38 64813 262144 33659432
test_one 4294967293 38 64813 262144 33659432
test_one 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
test_one 1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536

test_two foobar
test_two aratherlongstringindeedifyoucanbelieveitohmygoodnessthisisquitelongbutitsalsorathersimpleinthatitsjustlowercaseletters
test_two "A much more complicated string, with spaces and punctuation."

