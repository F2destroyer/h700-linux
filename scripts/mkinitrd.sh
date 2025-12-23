#!/bin/bash

podman run --arch=arm64 --security-opt=label=disable \
	-v "${2:-./artifacts}:/artifacts" \
	-v ./mkinitcpio.conf:/tmp/mkinitcpio.conf:ro \
	--rm "docker.io/library/archlinux:${1:-latest}" \
	sh -c "pacman -Sy --noconfirm mkinitcpio linux && mkinitcpio -c /tmp/mkinitcpio.conf -k /usr/lib/modules/*/build/vmlinux -g /artifacts/initramfs"
