#!/bin/sh

apks=$(realpath "$(dirname "${0}")/../apks/gcc")

list='jansson-2.14.1-r0.apk
libstdc++-15.2.0-r2.apk
binutils-2.45.1-r0.apk
libgomp-15.2.0-r2.apk
libatomic-15.2.0-r2.apk
isl26-0.26-r1.apk
mpfr4-4.2.2-r0.apk
mpc1-1.3.1-r1.apk
gcc-15.2.0-r2.apk
make-4.4.1-r3.apk
musl-dev-1.2.5-r21.apk'

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

echo $apks
echo "${list}" | while read apk ; do
   apk add --allow-untrusted "${apks}/${apk}" --force-non-repository
done
gcc --version
make --version

confirm "install libgpiod"
apks=$(realpath "$(dirname "${0}")/../apks/gpio")
apk add --allow-untrusted "${apks}/libgpiod-2.2.2-r0.apk" "${apks}/pkgconf-2.5.1-r0.apk" "${apks}/libgpiod-dev-2.2.2-r0.apk" --force-non-repository
