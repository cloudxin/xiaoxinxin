#! /bin/bash

if [ -f Makefile ]
then
  make
fi

if [ ! -x formatter ]
then
  echo "--- No executable formatter found ---"
  exit 1
fi

function test_common {
  local fname=$1; shift
  local outline=$1
  local out_src=$(echo ${outline} | awk '{print $1}')
  local out_dst=$(echo ${outline} | awk '{print $2}')
  local out_len=$(echo ${outline} | awk '{print $3}')

  local shark=$(tshark -r ${fname} -Tfields -Eseparator=/s -e ip.src -e ip.dst -e ip.len)

  local s_src=$(echo ${shark} | awk '{print $1}')
  local s_dst=$(echo ${shark} | awk '{print $2}')
  local s_len=$(echo ${shark} | awk '{print $3}')

  if [ "x${out_src}" != "x${s_src}" ]
  then
    echo "--- Source incorrect ---"
    exit 1
  fi

  if [ "x${out_dst}" != "x${s_dst}" ]
  then
    echo "--- Destination incorrect ---"
    exit 1
  fi

  if [ "x${out_len}" != "x${s_len}" ]
  then
    echo "--- Length incorrect ---"
    exit 1
  fi
}

function test_icmp {
  local fname=$1
  local out=$(./formatter ${fname})
  echo ${out}

  test_common ${fname} "${out}"
  local proto=$(echo ${out} | awk '{print $4}')
  if [ "x${proto}" != "xICMP" ]
  then
    echo "--- Incorrect protocol ${proto}, should be ICMP ---"
    exit 1
  fi
  echo "+++ Correct ICMP packet +++"
}

function test_udp {
  local fname=$1
  local out=$(./formatter ${fname})
  echo ${out}

  test_common ${fname} "${out}"
  local proto=$(echo ${out} | awk '{print $4}')
  if [ "x${proto}" != "xUDP" ]
  then
    echo "--- Incorrect protocol ${proto}, should be UDP ---"
    exit 1
  fi
  local sport=$(echo ${out} | awk '{print $5}')
  local dport=$(echo ${out} | awk '{print $6}')

  local shark=$(tshark -r ${fname} -Tfields -Eseparator=/s -e udp.srcport -e udp.dstport)
  local s_sport=$(echo ${shark} | awk '{print $1}')
  local s_dport=$(echo ${shark} | awk '{print $2}')

  if [ "x${sport}" != "x${s_sport}" ]
  then
    echo "--- Incorrect source port ---"
    echo "    expected: ${s_sport}"
    echo "    received: ${sport}"
    exit 1
  fi

  if [ "x${dport}" != "x${s_dport}" ]
  then
    echo "--- Incorrect destination port ---"
    echo "    expected: ${s_dport}"
    echo "    received: ${dport}"
    exit 1
  fi

  echo "+++ Correct UDP packet +++"
}

function test_tcp {
  local fname=$1
  local out=$(./formatter ${fname})
  echo ${out}

  test_common ${fname} "${out}"
  local proto=$(echo ${out} | awk '{print $4}')
  if [ "x${proto}" != "xTCP" ]
  then
    echo "--- Incorrect protocol ${proto}, should be TCP ---"
    exit 1
  fi
  local sport=$(echo ${out} | awk '{print $5}')
  local dport=$(echo ${out} | awk '{print $6}')
  local flags=$(echo ${out} | awk '{print $7}')
  local seq=$(echo ${out} | awk '{print $8}')
  local ack=$(echo ${out} | awk '{print $9}')

  local shark=$(tshark -r ${fname} -o tcp.relative_sequence_numbers:FALSE -Tfields -Eseparator=/s -e tcp.srcport -e tcp.dstport -e tcp.flags -e tcp.seq -e tcp.ack)
  local s_sport=$(echo ${shark} | awk '{print $1}')
  local s_dport=$(echo ${shark} | awk '{print $2}')
  local s_flags=$(echo ${shark} | awk '{print $3}')
  local s_seq=$(echo ${shark} | awk '{print $4}')
  local s_ack=$(echo ${shark} | awk '{print $5}')

  if [ "x${sport}" != "x${s_sport}" ]
  then
    echo "--- Incorrect source port ---"
    echo "    expected: ${s_sport}"
    echo "    received: ${sport}"
    exit 1
  fi

  if [ "x${dport}" != "x${s_dport}" ]
  then
    echo "--- Incorrect destination port ---"
    echo "    expected: ${s_dport}"
    echo "    received: ${dport}"
    exit 1
  fi

  local sf_fin=$(( ${s_flags} & 1 ))
  local sf_syn=$(( ${s_flags} & 2 ))
  local sf_rst=$(( ${s_flags} & 4 ))
  local sf_psh=$(( ${s_flags} & 8 ))
  local sf_ack=$(( ${s_flags} & 16 ))
  local sf_urg=$(( ${s_flags} & 32 ))
  if [ ${sf_ack} -eq 0 ]
  then
    s_ack="-"
  fi

  local f_fin=0
  local f_syn=0
  local f_rst=0
  local f_psh=0
  local f_ack=0
  local f_urg=0
  for f in $(echo ${flags} | sed 's/,/ /g')
  do
    if [ $f == "FIN" ]
    then
      f_fin=1
    elif [ $f == "SYN" ]
    then
      f_syn=2
    elif [ $f == "RST" ]
    then
      f_rst=4
    elif [ $f == "PSH" ]
    then
      f_psh=8
    elif [ $f == "ACK" ]
    then
      f_ack=16
    elif [ $f == "URG" ]
    then
      f_urg=32
    fi
  done
  if [ ${sf_fin} -ne ${f_fin} ]
  then
    echo "--- Bad FIN flag ---"
    exit 1
  fi
  if [ ${sf_syn} -ne ${f_syn} ]
  then
    echo "--- Bad SYN flag ---"
    exit 1
  fi
  if [ ${sf_rst} -ne ${f_rst} ]
  then
    echo "--- Bad RST flag ---"
    exit 1
  fi
  if [ ${sf_psh} -ne ${f_psh} ]
  then
    echo "--- Bad PSH flag ---"
    exit 1
  fi
  if [ ${sf_ack} -ne ${f_ack} ]
  then
    echo "--- Bad ACK flag ---"
    exit 1
  fi
  if [ ${sf_urg} -ne ${f_urg} ]
  then
    echo "--- Bad URG flag ---"
    exit 1
  fi

  if [ "x${seq}" != "x${s_seq}" ]
  then
    echo "--- Incorrect sequence number ---"
    echo "    expected: ${s_seq}"
    echo "    received: ${seq}"
    exit 1
  fi

  # XXX -- need to check for "-"
  if [ "x${ack}" != "x${s_ack}" ]
  then
    echo "--- Incorrect acknowledgment number ---"
    echo "    expected: ${s_ack}"
    echo "    received: ${ack}"
    exit 1
  fi

  echo "+++ Correct TCP packet +++"
}

test_icmp icmp.pcap
test_udp udp.pcap
test_tcp tcp_syn.pcap
test_tcp tcp_ack.pcap
test_tcp tcp_psh_ack.pcap
