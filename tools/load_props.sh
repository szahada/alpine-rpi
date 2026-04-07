#!/bin/bash

confirm () {
  echo -e "${1}"
  read -p "are you sure? " -n 1 -r
  if [[ ! ${REPLY} =~ ^[Yy]$ ]]
  then
    echo $'\n'"bye"
    exit
  else
    echo ""
  fi
}

if [ -z "${tools}" ]
then
  echo "tools directory is not set"
  exit 1
fi

if [ $# -ne 1 ]
then
  echo "config file is required"
  return 1 
fi

. "${tools}/props.sh" "${1}" || exit_code=$?
if [ ! -z "${exit_code}" ]
then
  echo "$(basename "$0") error"
  exit 1
fi

load "${1}"

# set defaults
if [ -z "$(get overlay)" ]
then
  put "overlay" "alpine-rpi"
fi

if [ -z "$(get hostname)" ]
then
  put "hostname" "alpine"
fi

if [ -z "$(get ap_ssid)" ]
then
  put "name" "$(get hostname)"
fi

if [ -z "$(get ap_lease)" ]
then
  put "ap_lease" "24h"
fi

if [ -z "$(get g_lease)" ]
then
  put "g_lease" "24h"
fi

# check config
check_required () {
  array=("$@") 
  for item in "${array[@]}"
  do
    if [ -z "$(get ${item})" ]
    then
      echo "${item} not bound check config"
      exit 1
    fi
  done
}

# required config
declare -a required=(version arch device mount)
check_required "${required[@]}"

# required for expert mode
required=(system data swap)
if [ ! -z "${expert}" ]&&[ "${expert}" -eq 1 ]
then
  check_required "${required[@]}"
else
  for item in "${required[@]}"
  do
    del "${item}"
  done
fi

# required for wifi
required=(country ssid psk)
if [ ! -z "$(get wifi)" ]&&[ "$(get wifi)" -eq 1 ]
then
  check_required "${required[@]}"
else
  for item in "${required[@]}"
  do
    del "${item}"
  done
  del "wifi"
fi

# required for ap
required=(ap_ssid ap_psk ap_addr ap_mask ap_range ap_lease)
if [ ! -z "$(get ap)" ]&&[ "$(get ap)" -eq 1 ]
then
  check_required "${required[@]}"
else
  for item in "${required[@]}"
  do
    del "${item}"
  done
  del "ap"
fi

# required for gadget
required=(g_addr g_mask g_range g_lease)
if [ ! -z "$(get gadget)" ]&&[ "$(get gadget)" -eq 1 ]
then
  check_required "${required[@]}"
else
  for item in "${required[@]}"
  do
    del "${item}"
  done
  del "gadget"
fi

put "tgz" "$(get overlay)-$(get version)-$(get arch).tar.gz"

# verify config
verify () {

# check device
  echo q | fdisk "$(get device)" &>/dev/null || exit_code=$?
  if [ ! -z "${exit_code}" ]
  then
    echo "device $(get device) error"
    #exit "${exit_code}"
  fi

# check mount
  if [ ! -d "$(get mount)" ]
  then
    echo "mount $(get mount) error"
    exit 1
  fi

# check arch
  arch="${images}/$(get tgz)"
  if [ ! -f "${arch}" ]
  then
    echo "${arch} doesnt exist,"
    echo "downloading .."
    #exit 1
    wget -q "https://dl-cdn.alpinelinux.org/alpine/v$(get version | cut -d'.' -f1,2)/releases/$(get arch)/$(get tgz)" -P "${images}"
  fi

# check current version
  version=$(wget -qO- https://dl-cdn.alpinelinux.org/alpine/ | awk -F'["/]' '{print $2}' | grep 'v[1-9]' | awk -F'.' '{print $1,$2}' | sort -k2n | tr ' ' '.' | tail -1)
  release=$(wget -qO- https://dl-cdn.alpinelinux.org/alpine/"${version}"/releases/"$(get arch)"/ | cut -d'"' -f2 | grep "$(get overlay).*-$(get arch)\.tar\.gz$" | tr '.' ' ' | sort -k3nr | tr ' ' '.' | head -1)
  if [ "${release}" != "$(get tgz)" ]
  then
    confirm "will install $(get tgz)\nand current is ${release}"
  fi

  return 0
}

