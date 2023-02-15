#!/bin/bash
processData() {
    raw_data=$(curl -s https://asn.bgp.space/${i}.html | sed "s/<[^>]*>//g")
    total_num=$(echo "${raw_data}" | grep -n "数据共计条数" | awk -F: '{print $3}')
    begin_num=$(echo "${raw_data}" | grep -n "BEGIN" | awk -F: '{print $1}')
    begin_num=$(( begin_num + 1))
    end_num=$(( begin_num +  total_num - 1))
    tmp_data=$(echo "${raw_data}" | sed -n "$begin_num"",""$end_num""p")
    data=$(echo "${tmp_data}" | sed ':a;N;$!ba;s/\n/;\n/g')
    data="acl ""$name"" {"$'\n'""$data";"$'\n'"};"
    echo "${data}" > China-ISP/$name
    echo [INFO] Write $i to $name Complete.
}
loopProcess() {
for i in china china6 chinanet chinanet6 unicom unicom6 cmcc cmcc6 cernet cernet6 cstnet cstnet6; do
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
}
start() {
last_date=$(cat time)
raw_data=$(curl -sL https://asn.bgp.space | sed "s/<[^>]*>//g")
time_num=$(($(echo "$raw_data" | grep -n "所有IP地址段" | awk -F: '{print $1}') + 1))
curr_date=$(date -d "$(echo "$raw_data" | sed -n "$time_num""p")" +%s)
if [ "$curr_date" -gt "$last_date" ]
then
    echo "[INFO] New data found! Process Start"
    loopProcess
    echo "$curr_date" > time
    if [ $GITHUB_TOKEN ]
    then
        git add .
        git config user.name ${COMMIT_USER}
        git config user.email ${COMMIT_EMAIL}
        git commit -m "Updated by Actions at `date +'%Y-%m-%d %H:%M:%S'`"
        git push -u origin ${DEPLOY_BRANCH}
    else
        echo "[INFO] Process End"
        return 0
    fi
else
    echo "[INFO] No needs to update. Program will exit automatically"
    return 0
fi
}
start
