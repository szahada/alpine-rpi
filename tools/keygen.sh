#! /bin/bash

if [ -z "$(get rootdir)" ]&&[ -z "${1}" ]
then
  echo "rootdir is not set"
  exit 1
fi

if [ ! -z "${1}" ]
then
  ssl="${1}"
else
  ssl="$(get rootdir)/ssl" 
fi

if [ ! -d "${ssl}" ]
then
  echo "${ssl} doesnt exist"
  exit 1
fi

ssh-keygen -t ed25519 -f "${ssl}/root_id_ed25519_key" -N ''

