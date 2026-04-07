#!/bin/bash

if [ $(whoami) != "root" ]
then
  echo "you must be root"
  exit 1
fi

route=$(ip route list | grep default | grep -v wlo1)
device=$(echo "${route}" | awk '{print $1,$4,$5}')
ip route del ${device}
ip route add $(echo "${route}" | cut -d' ' -f1-10) 1000
ip route list

