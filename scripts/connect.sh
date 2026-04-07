#!/bin/bash

ip=192.168.0.100

if [ ! -z "${1}" ]
then
  ip="${1}"
fi

ssh -i "$(realpath "$(dirname "${0}")/../ssl")/root_id_ed25519_key" "root@${ip}"

