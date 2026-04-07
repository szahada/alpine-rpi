#!/bin/bash

rootdir=$(realpath $(dirname "${0}"))
  #echo "${rootdir}"
scripts=$(realpath "${rootdir}/scripts")
if [ ! -d "${scripts}" ]
then
  echo "${scripts} not found"
  #exit 1
fi
tools=$(realpath "${rootdir}/tools")
if [ ! -d "${tools}" ]
then
  echo "${tools} not found"
  exit 1
fi
images=$(realpath "${rootdir}/images")
if [ ! -d "${images}" ]
then
  echo "${images} not found"
  exit 1
fi
ovl=$(realpath "${rootdir}/ovl")
if [ ! -d "${ovl}" ]
then
  echo "${ovl} not found"
  exit 1
fi


usage () {
  echo "usage: $(basename "$0") [-h] | -f sample.cfg [-i] | [-a sample.apks][-x]"
  echo -e "h\tprint this HELP"
  echo -e "\nf\tconfig FILE (required)"
  echo -e "i\tconfig INFO"
  echo -e "a\tclone APKS"
  echo -e "x\tpartitioning EXPERT"
}

while getopts "hixa:f:" opt
do
  case $opt in
    h) usage
       exit 0
    ;;
    f) config="${OPTARG}"
    ;;
    i) info=1
    ;;
    a) apks="${OPTARG}"
    ;;
    x) expert=1
    ;;
    :) echo "option ${OPTARG} requires an argument"
    ;;
    ?) echo "invalid option ${OPTARG}"
       usage
       exit 1
    ;;
    esac
done

shift $((OPTIND-1))

if [ ! -z "${@}" ]
then
  echo "invalid args are: [${@}]"
  usage
  exit 1
fi

if [ ! -f "${config}" ]
then
  usage
fi

if [ $(whoami) != "root" ]
then
  echo "you must be root"
  exit 1
fi

if [ $(env | grep PATH | grep sbin | wc -l) -ne 1 ]
then
  echo "no sbin in your PATH"
  exit 1
fi

. "${tools}/load_props.sh" "$(realpath "${config}")" || exit_code=$?
if [ ! -z "${exit_code}" ]
then
  usage
  exit "${exit_code}"
fi

put "rootdir" "${rootdir}"

if [ ! -z "${expert}" ]&&[ "${expert}" -ne 0 ]
then
  put "expert" "${expert}"
fi

if [ ! -z "${info}" ]&&[ "${info}" -eq 1 ]
then
  print
  verify
  exit 0
fi

echo "verify properties"
verify
echo "install $(get tgz)"

if [ ! -z "${apks}" ]&&[ -f "${apks}" ]
then
  . "${tools}/clone_apks.sh" "$(realpath "${apks}")"
  if [ $? -ne 0 ]
  then
    exit 1
  fi
fi

. "${tools}/prepare_disk.sh"
if [ $? -ne 0 ]
then
  exit 1
else
  count_parts
fi

# verify ovl scripts
declare -a items=(commons.sh basic.sh gadget.sh ap.sh wifi.sh)
for item in "${items[@]}"
do
  . "${ovl}/${item}" || exit_code=$?
  if [ ! -z "${exit_code}" ]
  then
    exit "${exit_code}"
  fi
done

#############################################
#print
#info

# unmount all
while IFS= read -r line
do
  echo "unmount ${line}"
  umount "${line}" 2>/dev/null
done <<< "$(info | awk '{print $1}')"

if [ ! -z "$(get expert)" ]&&[ "$(get expert)" -eq 1 ]
then
  expert_mode
fi

check_disk
if [ $? -ne 0 ]
then
  echo "partition requirements are not met"
  exit 1
fi

format_sys

# untar archive
tar --checkpoint=1000 -p -s --atime-preserve --same-owner --one-top-level="$(get mount)" -zxf "${images}/$(get tgz)"

cleanup
keys
display
gpiomem
sshd
install rsync
basic

if [ ! -z "$(get gadget)" ]&&[ "$(get gadget)" -eq 1 ]
then
  install dnsmasq
  gadget
fi

if [ ! -z "$(get wifi)" ]&&[ "$(get wifi)" -eq 1 ]
then
  wifi
elif [ ! -z "$(get ap)" ]&&[ "$(get ap)" -eq 1 ]
then
  install dnsmasq
  install hostapd
  ap_mode
fi

more_apks tcpdump
more_apks git
more_apks nodejs
more_apks pkgconf
more_apks libgpiod community
more_apks make
more_apks gcc
more_apks awall
more_apks sqlite
more_apks odbc

<<'TODO'
npm
TODO

chown -R 1000:1000 "${rootdir}"
deploy

#############################################

