#!/bin/sh
# This script runs inside an aarch64 Arch Linux ARM container and creates a
# base rootfs tarball with wifi support and an ssh daemon active at boot.
set -e

target="$(mktemp -d)"
trap 'rm -rf "$target"' 0

# Initialize pacman keyring and update
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm

# Install arch-install-scripts to get pacstrap
pacman -S --noconfirm arch-install-scripts

# Install base system and required packages
pacstrap -c "$target" base wpa_supplicant openssh dhcpcd

# Setup resolv.conf
echo "nameserver 8.8.8.8" >"$target/etc/resolv.conf"

# Setup hostname
echo h700 >"$target/etc/hostname"

# Setup kernel module loading
mkdir -p "$target/etc/modules-load.d"
echo 8821cs >"$target/etc/modules-load.d/wifi.conf"

# Setup network interfaces (using systemd-networkd)
mkdir -p "$target/etc/systemd/network"
cat >"$target/etc/systemd/network/20-wired.network" <<__EOF__
[Match]
Name=eth*

[Network]
DHCP=yes
__EOF__

cat >"$target/etc/systemd/network/25-wireless.network" <<__EOF__
[Match]
Name=wlan0

[Network]
DHCP=yes
__EOF__

# Setup getty on serial console
mkdir -p "$target/etc/systemd/system/getty.target.wants"
ln -sf /usr/lib/systemd/system/getty@.service "$target/etc/systemd/system/getty.target.wants/getty@ttyS0.service"

# Enable services
mkdir -p "$target/etc/systemd/system/multi-user.target.wants"
for svc in sshd systemd-networkd systemd-resolved wpa_supplicant@wlan0 ; do
    ln -sf "/usr/lib/systemd/system/${svc}.service" "$target/etc/systemd/system/multi-user.target.wants/${svc}.service"
done

# Setup MOTD
cat >"$target/etc/motd" <<__EOF__
Welcome to Arch Linux ARM!

This is an unofficial port to the Allwinner H700 SoC: please report
issues to https://github.com/F2destroyer/h700-linux .

The Arch Linux ARM Wiki contains a large amount of how-to guides and general
information about administrating Arch Linux ARM systems.
See <https://archlinuxarm.org/>.

You may change this message by editing /etc/motd.

__EOF__

tar cf "${1:-/tmp/rootfs.tar}" -C "$target" .
