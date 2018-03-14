#!/bin/bash
###AUTHOR###
#Harry Dove-Robinson 2018-03-05
#harry@doverobinson.me
#https://gist.github.com/hdoverobinson
#https://github.com/hdoverobinson

export INIT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$EUID" -ne 0 ]
then echo "This script must be run as root!"
exit 1
fi &&

if ! [[ "$@" =~ .*-y.* ]]
then
echo "$(tput setaf 1 2> /dev/null)Before running, make sure you set an IP address in $INIT_DIR/etc/network/interfaces! Continue? (yes/no)$(tput sgr0 2> /dev/null)" &&
read -r REPLY &&
REPLY=${REPLY,,} &&
if ! [[ $REPLY =~ ^(yes|y) ]]
then
echo "$(tput setaf 1 2> /dev/null)Aborting!$(tput sgr0 2> /dev/null)" &&
exit 1
fi
fi &&

GET_REVISION="$(cat /proc/cpuinfo | grep 'Revision' | awk '{print $3}')" &&
RPI_MODEL="$(cat "$INIT_DIR/rpi-identifiers.txt" | tail -n+3 | grep "$GET_REVISION" | awk '{print $2}')" &&

if [[ -z "$RPI_MODEL" ]]
then
echo "$(tput setaf 1 2> /dev/null)Could not identify Raspberry Pi model.
Aborting!$(tput sgr0 2> /dev/null)" &&
exit 1
fi &&

echo "Starting raspbian-reducer!" &&

echo "Restoring network interfaces..." &&
cp "${INIT_DIR}/${RPI_MODEL}"/etc/network/interfaces /etc/network/ &&
chown root:root /etc/network/interfaces &&
chmod 644 /etc/network/interfaces &&

echo "Restoring config.txt..." &&
cp "${INIT_DIR}/${RPI_MODEL}"/boot/{cmdline.txt,config.txt} /boot/ &&
chown root:root /boot/{cmdline.txt,config.txt} &&
chmod 755 /boot/{cmdline.txt,config.txt} &&

echo "Restoring raspbian-reducer_modprobe-blacklist.conf..." &&
cp "${INIT_DIR}/${RPI_MODEL}"/etc/modprobe.d/raspbian-reducer_modprobe-blacklist.conf /etc/modprobe.d/ &&
chown root:root /etc/modprobe.d/raspbian-reducer_modprobe-blacklist.conf &&
chmod 644 /etc/modprobe.d/raspbian-reducer_modprobe-blacklist.conf &&

echo "Restoring 90-raspbian-reducer_sysctl.conf..." &&
cp "${INIT_DIR}/${RPI_MODEL}"/etc/sysctl.d/90-raspbian-reducer_sysctl.conf /etc/sysctl.d/ &&
chown root:root /etc/sysctl.d/90-raspbian-reducer_sysctl.conf &&
chmod 744 /etc/sysctl.d/90-raspbian-reducer_sysctl.conf &&

echo "Restoring raspbian-reducer_cron..." &&
cp "${INIT_DIR}/${RPI_MODEL}"/etc/cron.d/raspbian-reducer_cron /etc/cron.d/ &&
chown root:root /etc/cron.d/raspbian-reducer_cron &&
chmod 755 /etc/cron.d/raspbian-reducer_cron &&

echo "Removing errant cron jobs..." &&
find /etc/cron* -type f ! -name ntp -a -type f ! -name fake-hwclock -a -type f ! -name crontab -type f ! -name raspbian-reducer_cron -delete &&

echo "Disabling apt timers..." &&
systemctl disable apt-daily.service &&
systemctl disable apt-daily.timer &&
systemctl disable apt-daily-upgrade.service &&
systemctl disable apt-daily-upgrade.timer &&

echo "Disabling HDMI..." &&
tvservice -o > /dev/null 2>&1 &&

echo "Disabling tty1..." &&
systemctl stop getty@tty1.service &&
systemctl disable getty@tty1.service &&

echo "Enabling SSHD..." &&
update-rc.d ssh defaults &&
update-rc.d ssh enable &&

echo "Setting CPU to performance mode..." &&
echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor &&

echo "Purging packages from $INIT_DIR/purge-packages.txt..." &&
for i in $(cat "$INIT_DIR/purge-packages.txt" | head -2 | sed -n 2p)
do
if dpkg --get-selections | grep -q $i
then
apt-get purge --auto-remove -qq $i
fi
done &&

echo "Done! If running script for the first time, please reboot!" &&

exit
