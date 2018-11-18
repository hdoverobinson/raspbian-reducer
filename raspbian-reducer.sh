#!/bin/bash
###AUTHOR###
#Harry Dove-Robinson 2018-08-26
#harry@doverobinson.me
#https://gist.github.com/hdoverobinson
#https://github.com/hdoverobinson

export INIT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export SCRIPT_PATH="$(realpath "$0")"

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
RPI_MODEL="$(cat "$INIT_DIR/rpi-identifiers.txt" | tail -n+3 | grep "$GET_REVISION" | head -1 | awk '{print $2}')" &&

if [[ -z "$RPI_MODEL" ]]
then
echo "$(tput setaf 1 2> /dev/null)Could not identify Raspberry Pi model.
Aborting!$(tput sgr0 2> /dev/null)" &&
exit 1
fi &&

echo "Starting $(basename "$0")!" &&

echo "Restoring network interfaces..." &&
cp "${INIT_DIR}/${RPI_MODEL}"/etc/network/interfaces /etc/network/ &&
chown root:root /etc/network/interfaces &&
chmod 644 /etc/network/interfaces &&

echo "Restoring cmdline.txt and config.txt..." &&
cp "${INIT_DIR}/${RPI_MODEL}"/boot/{cmdline.txt,config.txt} /boot/ &&
chown root:root /boot/{cmdline.txt,config.txt} &&
chmod 755 /boot/{cmdline.txt,config.txt} &&

echo "Restoring fstab..." &&
cp "${INIT_DIR}/${RPI_MODEL}"/etc/fstab /etc/fstab &&
chown root:root /etc/fstab &&
chmod 644 /etc/fstab &&

echo "Restoring radio blacklist raspbian-reducer_modprobe-blacklist.conf..." &&
cp "${INIT_DIR}/${RPI_MODEL}"/etc/modprobe.d/raspbian-reducer_modprobe-blacklist.conf /etc/modprobe.d/ &&
chown root:root /etc/modprobe.d/raspbian-reducer_modprobe-blacklist.conf &&
chmod 644 /etc/modprobe.d/raspbian-reducer_modprobe-blacklist.conf &&
systemctl disable hciuart.service &&

echo "Restoring 90-raspbian-reducer_sysctl.conf..." &&
cp "${INIT_DIR}/${RPI_MODEL}"/etc/sysctl.d/90-raspbian-reducer_sysctl.conf /etc/sysctl.d/ &&
chown root:root /etc/sysctl.d/90-raspbian-reducer_sysctl.conf &&
chmod 744 /etc/sysctl.d/90-raspbian-reducer_sysctl.conf &&

echo "Restoring rc.local..." &&
cat "${INIT_DIR}/${RPI_MODEL}"/etc/rc.local | sed "s@SCRIPT_PATH@$SCRIPT_PATH@g" > /etc/rc.local &&
chown root:root /etc/rc.local &&
chmod 755 /etc/rc.local &&

echo "Disabling video output..." &&
vcgencmd display_power 0 > /dev/null 2>&1 &&
tvservice -o > /dev/null 2>&1 &&

echo "Enabling SSHD..." &&
update-rc.d ssh defaults &&
update-rc.d ssh enable &&

echo "Setting CPU to performance mode..." &&
echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor &&

echo "Disabling services from $INIT_DIR/services-disabled.txt..." &&
for i in $(cat "$INIT_DIR/services-disabled.txt" | head -2 | sed -n 2p)
do
systemctl stop $i &&
systemctl disable $i
done &&

echo "Purging packages from $INIT_DIR/packages-purged.txt..." &&
for i in $(cat "$INIT_DIR/packages-purged.txt" | head -2 | sed -n 2p)
do
if dpkg --get-selections | grep -q $i
then
apt-get purge --auto-remove -qq $i
fi
done &&

systemctl daemon-reload &&

echo "Done! If running script for the first time, please reboot!" &&

exit
