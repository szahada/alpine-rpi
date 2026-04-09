#!/bin/bash

if [ -z "$(get rootdir)" ]
then
  echo "rootdir is not set"
  exit 1
fi
overlay="$(get rootdir)/$(get overlay).apkovl"

# basic config
basic () {

# create basic.sh
  echo "#!/bin/sh

logger -st \"$(get overlay)\" set date
date -s \"2026-04-01 00:00:01\"

logger -st \"$(get overlay)\" set colors
mv /etc/profile.d/color_prompt.sh.disabled /etc/profile.d/color_prompt.sh

logger -st \"$(get overlay)\" set aliases
echo \"alias ll=\\\"ls -la\\\"
alias ..=\\\"cd ..\\\"
\" >> /etc/profile.d/aliases.sh

logger -st \"$(get overlay)\" set hostname
echo \"$(get hostname)\" > /etc/hostname
hostname -F /etc/hostname
sed -i \"s/$/ $(get hostname)/\" /etc/hosts 

logger -st \"$(get overlay)\" set swap
mkswap $(info | head -2 | tail -1 | awk '{print $1}')
swapon $(info | head -2 | tail -1 | awk '{print $1}')

logger -st \"$(get overlay)\" set permanent mountpoint
echo \"
$(info | head -2 | tail -1 | awk '{print $1}')  none    swap    sw              0       0
$(info | head -3 | tail -1 | awk '{print $1}')  /srv    ext4    defaults        0       2
\" > /etc/fstab
mount -a

logger -st \"$(get overlay)\" install apks
echo \"/srv/apks/main
/srv/apks/community\" >> /etc/apk/repositories
. /tmp/apk_install.sh

logger -st \"$(get overlay)\" localtime
ln -s /usr/share/zoneinfo/Europe/Warsaw /etc/localtime

logger -st \"$(get overlay)\" set lo
echo \"auto lo
iface lo inet loopback
\" >> /etc/network/interfaces
ifconfig lo up
: '
echo \"PermitRootLogin yes
AuthenticationMethods none
PermitEmptyPasswords yes\" > \"/etc/ssh/sshd_config.d/$(get overlay)_ssh.conf\"
'
echo \"PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no\" > \"/etc/ssh/sshd_config.d/$(get overlay)_ssh.conf\"

rc-service seedrng restart || rc-service urandom restart
rc-service sshd restart

logger -st \"$(get overlay)\" start cron
printf '*\t*\t*\t*\t*\t/srv/scripts/gen_motd.sh >> /var/log/cron 2>&1\n' >> /var/spool/cron/crontabs/root
rc-service crond start && rc-update add crond

logger -st \"$(get overlay)\" \${1} cleanup
rc-update --all delete \${1}
rm -f /run/\${1}.pid /tmp/\${1}.sh /etc/init.d/\${1}
rm -f /tmp/apk_install.sh
" > "${overlay}/tmp/basic.sh"
  chmod u+x "${overlay}/tmp/basic.sh"

# create basic service
echo "#!/sbin/openrc-run

name=\"alpine-rpi basic script\"

command=\"/tmp/\${RC_SVCNAME}.sh\"
command_background=true
pidfile=\"/run/\${RC_SVCNAME}.pid\"
command_args=\"\${RC_SVCNAME}\"

depend() {
  use logger
  want dev-settle
  need localmount
  after bootmisc hwdrivers modules
  before net
}
" > "${overlay}/etc/init.d/basic"
  chmod u+x "${overlay}/etc/init.d/basic" 
  cd "${overlay}/etc/runlevels/default" && ln -sf ../../init.d/basic . && cd -
}

