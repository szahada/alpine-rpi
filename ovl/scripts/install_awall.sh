apk add awall --force-non-repository

modprobe -v ip_tables
modprobe -v ip6_tables
modprobe -v iptable_nat

rc-update add iptables
rc-update add ip6tables
iptables-save > /etc/iptables/rules-save
ip6tables-save > /etc/iptables/rules6-save
  #rc-service iptables start
  #rc-service ip6tables start
cp deny-all.json /etc/awall/optional/
cp ssh.json /etc/awall/optional/
cp dhcp.json /etc/awall/optional/
awall list
awall enable deny-all
awall enable ssh
awall enable dhcp
awall list

echo "start: awall activate"

