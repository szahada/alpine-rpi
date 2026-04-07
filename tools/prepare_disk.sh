#!/bin/bash
#set -xv

if [ -z "$(get device)" ]
then
  echo "device is not set"
  exit 1
fi

# get all disk partitions
info () {
  while IFS= read -r line
  do
    echo "${line}"
  done <<< "$((echo p; echo q) | fdisk "$(get device)" 2>/dev/null | grep "$(get device)[^:]" | sed 's/*/@/')"
}

# check if provided disk is valid for install
count_parts() {
  warn=0
  part_list=$(info)
  part_cnt=$(echo "${part_list}" | wc -l)
  echo -n "${part_cnt} partitions found on $(get device)"
  if [ "${part_cnt}" -ge 3 ]
  then
    echo " OK"
  else
    echo " ERROR"
    let warn++
    exit "${warn}"
  fi
}

check_disk () {
  warn=0
  part_list=$(info)

  #sys_part
  part_info=$(echo "${part_list}" | head -1 | tail -1)
  echo -n "$(echo ${part_info} | awk '{print $1}') is"
  if [ "$(echo "${part_info}" | awk '{print $2}')" != "@" ]
  then
    echo -n " NOT"
    let warn++
  fi
  echo -n " active,"
  part_size=$(echo "${part_info}" | awk '{print $6}')
  echo -n " size is ${part_size},"
  echo -n " type is "
  if [ "$(echo "${part_info}" | awk '{print $7}')" != 'c' ]
  then
    echo -n "in"
    let warn++
  fi
  echo -n "valid ($(echo "${part_info}" | awk '{for (i=8;i<=NF;++i) printf $i OFS; FS}' | sed 's/\s*$//'))"
  if [ "${warn}" -eq 0 ]
  then
    echo " OK"
  else
    echo " WARN"
  fi

  #swap
  part_info=$(echo "${part_list}" | head -2 | tail -1)
  echo -n "$(echo ${part_info} | awk '{print $1}')"
  part_size=$(echo "${part_info}" | awk '{print $5}')
  echo -n " size is ${part_size},"
  echo -n " type is "
  if [ "$(echo "${part_info}" | awk '{print $6}')" != '82' ]
  then
    echo -n "in"
    let warn++
  fi
  echo -n "valid ($(echo "${part_info}" | awk '{for (i=7;i<=NF;++i) printf $i OFS; FS}' | sed 's/\s*$//'))"
  if [ "${warn}" -eq 0 ]
  then
    echo " OK"
  else
    echo " WARN"
  fi

  #data
  part_info=$(echo "${part_list}" | head -3 | tail -1)
  echo -n "$(echo ${part_info} | awk '{print $1}')"
  part_size=$(echo "${part_info}" | awk '{print $5}')
  echo -n " size is ${part_size},"
  echo -n " type is "
  if [ "$(echo "${part_info}" | awk '{print $6}')" != '83' ]
  then
    echo -n "in"
    let warn++
  fi
  echo -n "valid ($(echo "${part_info}" | awk '{for (i=7;i<=NF;++i) printf $i OFS; FS}' | sed 's/\s*$//'))"
  if [ "${warn}" -eq 0 ]
  then
    echo " OK"
  else
    echo " WARN"
  fi

  return ${warn}
}

format_sys () {
  diskpart=$(info | head -1 | awk '{print $1}')
  confirm "will erase all data on ${diskpart}"

  # format partition
  label="sys-$(get hostname)"
  mkfs.vfat -n "${label^^}" -F 32 "${diskpart}"
  mount -t vfat  "${diskpart}" "$(get mount)"
}

expert_mode () {
  diskinfo=$(info)
  echo "${diskinfo}"
  confirm "all data on disk $(get device) will be lost"

  # remove existing partition(s)
  if [ $(echo "${diskinfo}" | wc -l) -eq 1 ]
  then
    (echo d; echo w) | fdisk "$(get device)" 1>/dev/null
  fi
  if [ $(echo "${diskinfo}" | wc -l) -gt 1 ]
  then
    while IFS= read -r line
    do
      (echo d; echo -n $'\n'; echo w) | fdisk "$(get device)" 1>/dev/null
    done <<< "$(echo "${diskinfo}")"
  fi

  # create sys partition
  (echo n; echo p; echo 1; echo 2048; echo "$(get system)"; echo t; echo 0c; echo a; echo w) | fdisk "$(get device)" 1>/dev/null
  partprobe "$(get device)"

 # create swap partition
  (echo n; echo p; echo 2; echo -n $'\n'; echo "$(get swap)"; echo t; echo 2; echo 82; echo w) | fdisk "$(get device)" 1>/dev/null
  partprobe "$(get device)"

  # create data partition
  (echo n; echo p; echo 3; echo -n $'\n'; echo "$(get data)"; echo w) | fdisk "$(get device)" 1>/dev/null
  partprobe "$(get device)"

  # format data partition
  diskpart=$(info | head -3 | tail -1 | awk '{print $1}')
  confirm "will erase all data on ${diskpart}"
  label="data-$(get hostname)"
  mkfs.ext4 -F -L "${label^^}" "${diskpart}"
}

