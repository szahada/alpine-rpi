#!/bin/bash

if [ -z "$(get rootdir)" ]
then
  echo "rootdir is not set"
  exit 1
fi

branches=('main' 'community')
branch="main"
if [ ! -z "${2}" ]&&[ $(printf "%s\n" ${branches[@]} | grep "${2}" | wc -l) -ne 0 ]
then
  branch="${2}"
fi

apks="$(get rootdir)/apks/${branch}/$(get arch)"
if [ -d "${apks}" ]
then
  echo "${apks} exists"
  #du "${apks}" -d1 -h
  #exit 1
fi

short=$(echo $(get version) | cut -d'.' -f1,2)
url="https://dl-cdn.alpinelinux.org/alpine/v${short}/${branch}/$(get arch)/"
echo "${url}"
apks_cnt=$(wget -qO- "${url}" | awk -F'"' '{print $2}' | grep -Ev '^$|\.\./' | grep -E -f "${1}" | wc -l)

confirm "download ${apks_cnt} packages to ${apks}"

mkdir -p "${apks}"
wget -qN "${url}APKINDEX.tar.gz" -P "${apks}"
while IFS= read -r apk
do
  wget -qN "${url}${apk}" -P "${apks}" && echo -n '.'
done <<< $(wget -qO- "${url}" | awk -F'"' '{print $2}' | grep -Ev '^$|\.\./' | grep -E -f "${1}")
echo -e $'\n'
du "${apks}" -d1 -h

