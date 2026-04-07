#!/bin/bash

if [ -z "$(get rootdir)" ]
then
  echo "rootdir is not set"
  exit 1
fi
overlay="$(get rootdir)/$(get overlay).apkovl"

# wifi config
wifi () {

  echo "apk add dhcpcd wpa_supplicant --virtual \"$(get overlay)_sta\" --force-non-repository
" >> "${overlay}/tmp/apk_install.sh"

# create wifi.sh
  echo "#!/bin/sh

logger -st \"$(get overlay)\" wait for basic lock
while [ -f \"/run/basic.pid\" ]
do
  sleep 1
done

echo \"country=$(get country)
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
\" > /etc/wpa_supplicant/wpa_supplicant.conf

wpa_passphrase \"$(get ssid)\" \"$(get psk)\" >> /etc/wpa_supplicant/wpa_supplicant.conf
sed -i '/#psk=/d' /etc/wpa_supplicant/wpa_supplicant.conf

logger -st \"$(get overlay)\" set wlan0
echo \"auto wlan0
iface wlan0 inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
\" >> /etc/network/interfaces
ifconfig wlan0 down
/etc/init.d/wpa_supplicant start
/etc/init.d/networking restart
rc-update add wpa_supplicant boot

logger -st \"$(get overlay)\" set ntp
ntpd -N -p pool.ntp.org -n -q

logger -st \"$(get overlay)\" \${1} cleanup
rc-update --all delete \${1}
rm -f /run/\${1}.pid /tmp/\${1}.sh /etc/init.d/\${1}
" >> "${overlay}/tmp/wifi.sh"
  chmod u+x "${overlay}/tmp/wifi.sh"

# create wifi service
  echo "#!/sbin/openrc-run

name=\"alpine-rpi wifi script\"

command=\"/tmp/\${RC_SVCNAME}.sh\"
command_background=true
pidfile=\"/run/\${RC_SVCNAME}.pid\"
command_args=\"\${RC_SVCNAME}\"

depend() {
    use logger
    after basic
    before net
}
" > "${overlay}/etc/init.d/wifi"
  chmod u+x "${overlay}/etc/init.d/wifi"
  cd "${overlay}/etc/runlevels/default" && ln -sf ../../init.d/wifi . && cd -
}

