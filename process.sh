#!/bin/bash
processData() {
    raw_data=$(curl -s https://bgp.space/${i}.html | sed "s/<[^>]*>//g")
    total_num=$(echo "${raw_data}" | grep -n "数据共计条数" | awk -F: '{print $3}')
    begin_num=$(echo "${raw_data}" | grep -n "BEGIN" | awk -F: '{print $1}')
    begin_num=$(($begin_num + 1))
    end_num=$(($begin_num + $total_num - 1))
    tmp_data=$(echo "${raw_data}" | sed -n "$begin_num"",""$end_num""p")
    data=$(echo "${tmp_data}" | sed ':a;N;$!ba;s/\n/;\n/g')
    data="acl ""$name"" {"$'\n'""$data";"
    echo "${data}" > China-ISP/$name
    echo [INFO] Write $i to $name Completed.
}

for i in china china6 chinanet chinanet6 unicom unicom6 cmcc cmcc6 tietong cernet cernet6 cstnet cstnet6; do
    case $i in
      china)
          name=china_ipv4_acl
          processData
          ;;
      china6)
          name=china_ipv6_acl
          processData
          ;;
      chinanet)
          name=ctcc_ipv4_acl
          processData
          ;;
      chinanet6)
          name=ctcc_ipv6_acl
          processData
          ;;
      unicom)
          name=cucc_ipv4_acl
          processData
          ;;
      unicom6)
          name=cucc_ipv6_acl
          processData
          ;;
      tietong)
          name=crc_ipv4_acl
          processData
          ;;
      cernet)
          name=enet_ipv4_acl
          processData
          ;;
      cernet6)
          name=enet_ipv6_acl
          processData
          ;;
      cstnet)
          name=cstnet_ipv4_acl
          processData
          ;;
      cstnet6)
          name=cstnet_ipv4_acl
          processData
          ;;
    esac
done
