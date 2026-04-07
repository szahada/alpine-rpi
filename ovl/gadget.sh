#!/bin/bash

if [ -z "$(get rootdir)" ]
then
  echo "rootdir is not set"
  exit 1
fi
overlay="$(get rootdir)/$(get overlay).apkovl"

# gadget config
gadget () {
  echo "dtoverlay=dwc2,dr_mode=peripheral" >> "$(get mount)/usercfg.txt"

# create gadget.sh
  echo "#!/bin/sh

logger -st \"$(get overlay)\" wait for basic lock
while [ -f \"/run/basic.pid\" ]
do
  sleep 1
done

logger -st \"$(get overlay)\" set gadget
modprobe g_ether

logger -st \"$(get overlay)\" set usb0
echo \"auto usb0
allow-hotplug usb0
    iface usb0 inet static
    address $(get g_addr)
    netmask $(get g_mask)
\" >> /etc/network/interfaces

echo \"interface=usb0
dhcp-range=$(get g_range),$(get g_mask),$(get g_lease)
\" >> /etc/dnsmasq.d/gadget.conf

rc-update add dnsmasq
rc-service dnsmasq restart
ifup usb0
/etc/init.d/networking restart

logger -st \"$(get overlay)\" \${1} cleanup
rc-update --all delete \${1}
rm -f /run/\${1}.pid /tmp/\${1}.sh /etc/init.d/\${1}
" > "${overlay}/tmp/gadget.sh"
  chmod u+x "${overlay}/tmp/gadget.sh"

# create gadget service
  echo "#!/sbin/openrc-run

name=\"alpine-rpi gadget script\"

command=\"/tmp/\${RC_SVCNAME}.sh\"
command_background=true
pidfile=\"/run/\${RC_SVCNAME}.pid\"
command_args=\"\${RC_SVCNAME}\"

depend() {
  use logger
  after basic
  before net
}
" > "${overlay}/etc/init.d/gadget"
  chmod u+x "${overlay}/etc/init.d/gadget"
  cd "${overlay}/etc/runlevels/default" && ln -sf ../../init.d/gadget . && cd -
}

