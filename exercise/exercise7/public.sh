#! /bin/bash

if [ ! -x http ]
then
    echo "--- No executable file http found ---"
    exit 1
fi

function test_one {
    local fpcap=$1; shift
    local saddr=$1; shift # 0.15
    local sport=$1; shift # 0.15
    local daddr=$1; shift # 0.15
    local dport=$1; shift # 0.15
    local methd=$1; shift # 0.12
    local hostn=$1; shift # 0.12
    local rquri=$1; shift # 0.12
    local rcode=$1; shift # 0.12
    local ctype=$1; shift # 0.12

    output=$(./http -f ${fpcap})
    if [ 0 -ne $? ]
    then
	echo "--- Script failed ---"
        exit 1
    fi

    local a_saddr=$(echo ${output} | awk -F '|' '{print $1}')
    local a_sport=$(echo ${output} | awk -F '|' '{print $2}')
    local a_daddr=$(echo ${output} | awk -F '|' '{print $3}')
    local a_dport=$(echo ${output} | awk -F '|' '{print $4}')
    local a_methd=$(echo ${output} | awk -F '|' '{print $5}')
    local a_hostn=$(echo ${output} | awk -F '|' '{print $6}')
    local a_rquri=$(echo ${output} | awk -F '|' '{print $7}')
    local a_rcode=$(echo ${output} | awk -F '|' '{print $8}')
    local a_ctype=$(echo ${output} | awk -F '|' '{print $9}')

    if [ "x${saddr}" != "x${a_saddr}" ]
    then
        echo "--- Incorrect source address ---"
        echo "    expected: ${saddr}"
        echo "    received: ${a_saddr}"
        exit 1
    fi

    if [ "x${daddr}" != "x${a_daddr}" ]
    then
        echo "--- Incorrect destination address ---"
        echo "    expected: ${daddr}"
        echo "    received: ${a_daddr}"
        exit 1
    fi

    if [ "x${sport}" != "x${a_sport}" ]
    then
        echo "--- Incorrect source port ---"
        echo "    expected: ${sport}"
        echo "    received: ${a_sport}"
        exit 1
    fi

    if [ "x${dport}" != "x${a_dport}" ]
    then
        echo "--- Incorrect destination port ---"
        echo "    expected: ${dport}"
        echo "    received: ${a_dport}"
        exit 1
    fi

    if [ "x${methd}" != "x${a_methd}" ]
    then
        echo "--- Incorrect request method ---"
        echo "    expected: ${methd}"
        echo "    received: ${a_methd}"
        exit 1
    fi

    if [ "x${hostn}" != "x${a_hostn}" ]
    then
        echo "--- Incorrect host name ---"
        echo "    expected: ${hostn}"
        echo "    received: ${a_hostn}"
        exit 1
    fi

    if [ "x${rquri}" != "x${a_rquri}" ]
    then
        echo "--- Incorrect request URI ---"
        echo "    expected: ${rquri}"
        echo "    received: ${a_rquri}"
        exit 1
    fi

    if [ "x${rcode}" != "x${a_rcode}" ]
    then
        echo "--- Incorrect response code ---"
        echo "    expected: ${rcode}"
        echo "    received: ${a_rcode}"
        exit 1
    fi

    if [ "x${ctype}" != "x${a_ctype}" ]
    then
        echo "--- Incorrect content-type ---"
        echo "    expected: ${ctype}"
        echo "    received: ${a_ctype}"
        exit 1
    fi

    echo "+++ Correct output for ${fpcap} +++"
}

dns_out=$(./http -f dns.pcap)
if [ "x${dns_out}" != "x" ]
then
    echo "--- Printed DNS packet ---"
    echo ${dns_out}
    exit 1
fi

icmp_out=$(./http -f icmp.pcap)
if [ "x${icmp_out}" != "x" ]
then
    echo "--- Printed ICMP packet ---"
    echo ${icmp_out}
    exit 1
fi

ssl_out=$(./http -f ssl.pcap)
if [ "x${ssl_out}" != "x" ]
then
    echo "--- Printed SSL packet ---"
    echo ${ssl_out}
    exit 1
fi

test_one 1.pcap "127.0.0.1" "48294" "127.0.0.1" "8000" "GET" "127.0.0.1:8000" "/" "" ""
test_one 2.pcap "127.0.0.1" "48388" "127.0.0.1" "8000" "GET" "127.0.0.1:8000" "/?username=fw&password=yougotme" "" ""
test_one 3.pcap "127.0.0.1" "47264" "127.0.0.1" "9000" "GET" "127.0.0.1:9000" "/README" "" ""
test_one 4.pcap "131.118.254.40" "80" "10.0.2.15" "47708" "" "" "" "200" "text/plain"
test_one 5.pcap "149.174.110.146" "80" "10.0.2.15" "33280" "" "" "" "301" ""

