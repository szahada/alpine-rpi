#!/bin/bash

ip=192.168.0.100

if [ ! -z "${1}" ]
then
  ip="${1}"
fi

key="$(realpath "$(dirname "${0}")/../ssl")/root_id_ed25519_key"

rsync -avh -e 'ssh -i '${key} --progress --delete "root@${ip}:/srv/projects/" "$(realpath "$(dirname "${0}")/../projects/")"
