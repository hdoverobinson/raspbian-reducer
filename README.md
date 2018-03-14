# raspbian-reducer
Performance optimizations for headless Raspberry Pi 2 and 3 running 2017-11-29-raspbian-stretch-lite or later

Configure the network settings in etc/network/interfaces as the script will remove DHCP. Radios are disabled so Ethernet or serial console must be used.

The script will install itself to cron to run at boot.

Optional: fstab entries for /tmp and /var/log as tmpfs to reduce writes to disk
