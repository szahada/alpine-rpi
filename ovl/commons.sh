#!/bin/bash

if [ -z "$(get rootdir)" ]
then
  echo "rootdir is not set"
  exit 1
fi

# cleanup
cleanup() {
  rm -rf "$(get rootdir)/ovl/apks/"*
  overlay="$(get rootdir)/$(get overlay).apkovl"
  rm -rf "${overlay}"*
  mkdir -p "${overlay}/etc/runlevels/default"
  mkdir -p "${overlay}/etc/init.d"
  mkdir -p "${overlay}/etc/ssh"
  mkdir -p "${overlay}/tmp"
  mkdir -p "${overlay}/root/.ssh" && chmod 700 "${overlay}/root/.ssh"
  touch "${overlay}/root/.ssh/authorized_keys" && chmod 600 "${overlay}/root/.ssh/authorized_keys"
  touch "${overlay}/tmp/apk_install.sh" && chmod u+x "${overlay}/tmp/apk_install.sh"
  touch "${overlay}/etc/.default_boot_services"
}

# generate or copy ssh keys
keys () {
  if [ ! -f "$(get rootdir)/ssl/$(get hostname)_rsa_key" ]||[ ! -f "$(get rootdir)/ssl/$(get hostname)_rsa_key.pub" ]
  then
    ssh-keygen -f "$(get rootdir)/ssl/$(get hostname)_rsa_key" -N ''
    ssh-keygen -t ecdsa -f "$(get rootdir)/ssl/$(get hostname)_ecdsa_key" -N ''
    ssh-keygen -t ed25519 -f "$(get rootdir)/ssl/$(get hostname)_ed25519_key" -N ''
  fi
  find "$(get rootdir)/ssl" -type f -name "$(get hostname)*" | xargs -I '{}' echo cp '{}' {} | sed "s?$(get rootdir)/ssl?${overlay}/etc/ssh?2;s?$(get hostname)?ssh_host?2" | bash
  if [ ! -f "$(get rootdir)/ssl/root_id_ed25519_key" ]
  then
    . "$(get rootdir)/tools/keygen.sh"
  fi 
  cat "$(get rootdir)/ssl/root_id_ed25519_key.pub" >> "${overlay}/root/.ssh/authorized_keys"
}

# minimal gpumem
display () {
  if [ ! -f "$(get rootdir)/ovl/start_cd.elf" ]||[ ! -f "$(get rootdir)/ovl/fixup_cd.dat" ]
  then
    . "$(get rootdir)/tools/get_firmware.sh"
  fi   
  cp "$(get rootdir)/ovl/start_cd.elf" "$(get mount)"
  cp "$(get rootdir)/ovl/fixup_cd.dat" "$(get mount)"
  echo "hdmi_force_hotplug=1
#gpu_mem=32
gpu_mem=16
start_file=start_cd.elf
fixup_file=fixup_cd.dat
" >> "$(get mount)/config.txt" # not to usercfg.txt
}

# needed by pigpiod
gpiomem () {
  sed -i 's/$/ iomem=relaxed/' "$(get mount)/cmdline.txt"
}

# install sshd
sshd () {
  echo "apk add openssh-server openssh-client --virtual \"$(get overlay)_ssh\" --force-non-repository
" >> "${overlay}/tmp/apk_install.sh"
}

# install more apks
more_apks () {
  if [ ! -z "${1}" ]&&[ -f "$(get rootdir)/ovl/${1}.apks" ]
  then
    name="${1}"
    echo "get ${name}"
  else
    echo "${1} not found"
    exit 1
  fi
  if [ $(find "$(get rootdir)/apks" -type f -exec basename {} ';' | grep -E -f "$(get rootdir)/ovl/${name}.apks" | wc -l) -eq $(cat "$(get rootdir)/ovl/${name}.apks" | wc -l) ]
  then
    echo "using cached in $(get rootdir)/apks"
  else
    . "$(get rootdir)/tools/clone_apks.sh" "$(get rootdir)/ovl/${name}.apks" "${2}"
  fi
}

install () {
  more_apks "${1}"
  echo "install ${1}"
  if [ $(grep "apk add ${1}" "${overlay}/tmp/apk_install.sh" | wc -l) -eq 0 ]
  then
    echo "apk add ${1} --force-non-repository" >> "${overlay}/tmp/apk_install.sh"
  fi
}

deploy () {
  #tree "${overlay}"
  #cd "${overlay}" && tar -zcvf "${overlay}.tar.gz" * && cd -
  cd "${overlay}" && tar -zcf "${overlay}.tar.gz" * && cd -
  cp "${overlay}.tar.gz" "$(get mount)"
  rm -rf "${overlay}"*
  umount "$(get mount)"
  mount $(info | head -3 | tail -1 | awk '{print $1}') "$(get mount)"
  rsync -avh --no-compress --progress --include='apks/***' --exclude='*' "$(get rootdir)/" "$(get rootdir)/ovl/"
  rsync -avh --no-compress --progress --delete --include={'scripts/***','apks/***'}  --exclude='*' "$(get rootdir)/ovl/" "$(get mount)"
  #du "$(get mount)" -d0 -h
  umount "$(get mount)"
}

