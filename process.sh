#!/bin/bash

BASE_URL="https://bgp.cheng.pet"

processData() {
    local url="${BASE_URL}/${i}.txt"
    local raw_data

    raw_data=$(curl -sf "$url")
    if [ $? -ne 0 ] || [ -z "$raw_data" ]; then
        echo "[WARN] Failed to fetch $url, skipping."
        return 1
    fi

    local data
    data=$(echo "$raw_data" | sed 's/$/;/')
    data="acl ${name} {"$'\n'"${data}"$'\n'"};";

    echo "${data}" > "China-ISP/${name}"
    echo "[INFO] Write ${i} to ${name} complete."
}

loopProcess() {
    declare -A ISP_MAP=(
        [china]=china_ipv4_acl
        [china6]=china_ipv6_acl
        [chinanet]=ctcc_ipv4_acl
        [chinanet6]=ctcc_ipv6_acl
        [unicom]=cucc_ipv4_acl
        [unicom6]=cucc_ipv6_acl
        [cmcc]=cmcc_ipv4_acl
        [cmcc6]=cmcc_ipv6_acl
        [cernet]=enet_ipv4_acl
        [cernet6]=enet_ipv6_acl
        [cstnet]=cstnet_ipv4_acl
        [cstnet6]=cstnet_ipv6_acl
        [drpeng]=drpeng_ipv4_acl
        [drpeng6]=drpeng_ipv6_acl
    )

    for i in "${!ISP_MAP[@]}"; do
        name="${ISP_MAP[$i]}"
        processData
    done
}

publishAclBranch() {
    local curr_date=$1
    local publish_branch="acl_publish"
    local tmp_dir
    tmp_dir=$(mktemp -d)

    echo "[INFO] Publishing to ${publish_branch}..."

    # 复制 ACL 文件和时间戳到临时目录
    cp China-ISP/* "${tmp_dir}/"
    echo "${curr_date}" > "${tmp_dir}/stats"

    # 用 git 的底层命令直接操作，不影响当前工作区
    local tree_hash commit_hash parent_hash

    # 把临时目录里的文件建成一个 git tree
    tree_hash=$(
        git hash-object -w "${tmp_dir}"/* | \
        paste - <(ls "${tmp_dir}") | \
        awk '{print "100644 blob " $1 "\t" $2}' | \
        git mktree
    )

    # 获取 acl_publish 的当前 HEAD 作为 parent（首次推送时为空）
    parent_hash=$(git ls-remote origin "${publish_branch}" | awk '{print $1}')

    if [ -n "$parent_hash" ]; then
        commit_hash=$(git commit-tree "$tree_hash" \
            -p "$parent_hash" \
            -m "Published at $(date +'%Y-%m-%d %H:%M:%S')")
    else
        commit_hash=$(git commit-tree "$tree_hash" \
            -m "Published at $(date +'%Y-%m-%d %H:%M:%S')")
    fi

    git push origin "${commit_hash}:refs/heads/${publish_branch}"

    rm -rf "${tmp_dir}"
    echo "[INFO] Published to ${publish_branch} complete."
}

start() {
    local last_date
    last_date=$(cat time 2>/dev/null || echo 0)

    local page_raw curr_date_str curr_date
    page_raw=$(curl -sf "${BASE_URL}")
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to fetch ${BASE_URL}"
        exit 1
    fi

    curr_date_str=$(echo "$page_raw" \
        | grep -oP '(?<=Updated: <span>)[^<]+')
    if [ -z "$curr_date_str" ]; then
        echo "[ERROR] Could not parse update time from homepage."
        exit 1
    fi

    curr_date=$(date -d "$curr_date_str" +%s)
    echo "[INFO] Remote updated at: $curr_date_str (${curr_date})"
    echo "[INFO] Local  last update: $last_date"

    if [ "$curr_date" -gt "$last_date" ]; then
        echo "[INFO] New data found! Process Start"
        mkdir -p China-ISP
        loopProcess
        echo "$curr_date" > time

        if [ "$GITHUB_TOKEN" ]; then
            git add .
            git config user.name "${COMMIT_USER}"
            git config user.email "${COMMIT_EMAIL}"
            git commit -m "Updated by Actions at $(date +'%Y-%m-%d %H:%M:%S')"
            git push -u origin "${DEPLOY_BRANCH}"

            publishAclBranch "$curr_date"
        else
            echo "[INFO] Process End"
        fi
    else
        echo "[INFO] No new data. Program will exit."
    fi
}

start