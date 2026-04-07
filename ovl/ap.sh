#!/bin/bash

if [ -z "$(get rootdir)" ]
then
  echo "rootdir is not set"
  exit 1
fi
overlay="$(get rootdir)/$(get overlay).apkovl"

# ap mode config
ap_mode () {

# create ap.sh
  echo "#!/bin/sh

logger -st \"$(get overlay)\" wait for basic lock
while [ -f \"/run/basic.pid\" ]
do
  sleep 1
done

logger -st \"$(get overlay)\" configure hostapd
echo \"driver=nl80211\" >> /etc/hostapd/hostapd.conf
sed -i '/^auth_algs=/s/=.*/=1/' /etc/hostapd/hostapd.conf
sed -i '/^ssid=/s/=.*/='$(get ap_ssid)'/' /etc/hostapd/hostapd.conf
echo \"wpa=2
wpa_passphrase=$(get ap_psk)
rsn_pairwise=CCMP
\" >> /etc/hostapd/hostapd.conf

echo \"auto wlan0
iface wlan0 inet static
    address $(get ap_addr)
    netmask $(get ap_mask)
\" >> /etc/network/interfaces

logger -st \"$(get overlay)\" set dhcpd
echo \"interface=wlan0
dhcp-range=$(get ap_range),$(get ap_mask),$(get ap_lease)
\" >> /etc/dnsmasq.d/ap.conf

rc-update add dnsmasq
rc-update add hostapd
ifup wlan0
rc-service dnsmasq restart
rc-service hostapd start

logger -st \"$(get overlay)\" \${1} cleanup
rc-update --all delete \${1}
rm -f /run/\${1}.pid /tmp/\${1}.sh /etc/init.d/\${1}
" >> "${overlay}/tmp/ap.sh"
  chmod u+x "${overlay}/tmp/ap.sh"

# create ap service
  echo "#!/sbin/openrc-run

name=\"alpine-rpi ap script\"

command=\"/tmp/\${RC_SVCNAME}.sh\"
command_background=true
pidfile=\"/run/\${RC_SVCNAME}.pid\"
command_args=\"\${RC_SVCNAME}\"

depend() {
    use logger
    after basic
    before net
}
" > "${overlay}/etc/init.d/ap"
  chmod u+x "${overlay}/etc/init.d/ap"
  cd "${overlay}/etc/runlevels/default" && ln -sf ../../init.d/ap . && cd -
}

