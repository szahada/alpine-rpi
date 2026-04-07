#!/bin/bash

if [ -z "$(get rootdir)" ]
then
  echo "rootdir is not set"
  exit 1
fi

url="https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/"

wget -qN "${url}fixup_cd.dat" -P "$(get rootdir)/ovl/"
wget -qN "${url}start_cd.elf" -P "$(get rootdir)/ovl/"

