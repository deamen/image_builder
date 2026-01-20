#!/bin/sh
# clean-image.sh
set -euxo pipefail

# Remove PermitRootLogin yes from sshd_config
sed -i '/PermitRootLogin yes/d' /etc/ssh/sshd_config

# stop logging services
rc-service syslog stop

# clean apk cache
apk cache clean

# clean APK index files
rm -f /var/cache/apk/*

# force logrotate to shrink logspace and remove old logs as well as truncate logs
logrotate -f /etc/logrotate.conf
rm -f /var/log/*-???????? /var/log/*.gz
rm -f /var/log/dmesg.old

##
# Empty various log files if they exist
##
log_files="
  /var/log/acpid.log
  /var/log/apk.log
  /var/log/cloud-init.log
  /var/log/cloud-init-output.log
  /var/log/messages
  /var/log/qemu-ga.log
  /var/log/wtmp
  "
for log_file in $log_files; do
  if [ -f "$log_file" ]; then
    cat /dev/null > "$log_file"
  fi
done

rm -f /etc/udev/rules.d/70*

# remove SSH host keys
rm -f /etc/ssh/*key*

# remove root users SSH history
rm -rf /root/.ssh/known_hosts

# Diasble root password login
# This also diable su - root from other users using password
passwd --lock root

# remove root shell history
rm -f /root/.ash_history
unset HISTFILE