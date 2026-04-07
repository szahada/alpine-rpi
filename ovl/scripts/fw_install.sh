#!/bin/sh

apks=$(realpath "$(dirname "${0}")/../apks/awall")

list='libmnl-1.0.5-r2.apk
libnftnl-1.3.0-r0.apk
libxtables-1.8.11-r1.apk
iptables-1.8.11-r1.apk
iptables-openrc-1.8.11-r1.apk
ldns-1.8.4-r1.apk
drill-1.8.4-r1.apk
ipset-7.24-r0.apk
lua5.4-libs-5.4.8-r0.apk
readline-8.3.1-r0.apk
lua5.4-5.4.8-r0.apk
lua5.4-alt-getopt-0.8.0-r1.apk
lua5.4-cjson-2.1.0-r11.apk
lua5.4-pc-1.0.0-r12.apk
lua5.4-bit32-5.3.0-r6.apk
lua5.4-posix-36.3-r0.apk
lua5.4-stringy-0.5.1-r3.apk
lua-stdlib-debug-1.0.1-r1.apk
lua-stdlib-normalize-2.0.3-r1.apk
lua5.4-lyaml-6.2.8-r1.apk
lua-schema-0_git20170304-r2.apk
xtables-addons-3.30-r0.apk
awall-1.14.0-r0.apk'

echo $apks
echo "${list}" | while read apk ; do
   apk add --allow-untrusted "${apks}/${apk}" --force-non-repository
done

modprobe -v ip_tables
modprobe -v ip6_tables
modprobe -v iptable_nat

rc-update add iptables
rc-update add ip6tables
iptables-save > /etc/iptables/rules-save
ip6tables-save > /etc/iptables/rules6-save
  #rc-service iptables start
  #rc-service ip6tables start
cp "${apks}/deny-all.json" /etc/awall/optional/
cp "${apks}/ssh.json" /etc/awall/optional/
cp "${apks}/dhcp.json" /etc/awall/optional/
awall list
awall enable deny-all
awall enable ssh
awall enable dhcp
awall list

echo "start: awall activate"
