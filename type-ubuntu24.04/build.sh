#!/bin/bash
set -e

# Check if root
if [[ $EUID -ne 0 ]]; then
 echo "This script must be run as root"
 exit 1
fi

SCRIPT_DIR="$(
 cd "$(dirname "$0")" >/dev/null 2>&1
 pwd -P
)"

mkdir -p "$SCRIPT_DIR/temp"
RPATH="$SCRIPT_DIR/temp/rootfs.ext4"

usage() {
 echo "\
Usage: $0 [-t]
    -s don't generate a sparse file
"
}

SPARSE=1 # 1 if creating sparse file, 0 if not

while getopts "h?s" opt; do
 case "$opt" in
 h | \?)
  usage
  exit 0
  ;;
 s)
  echo "Disabled sparse file creation."
  SPARSE=0
  shift
  ;;
 esac
done

# Clean up old files
if [[ -f "$RPATH" ]]; then
 rm -rf "$RPATH"
fi

export SPARSE="$SPARSE"

"./init-rootfs.sh" "$RPATH"
"./run-container.sh" "$RPATH"


mkdir -p /mnt/ubuntu24.04/rootfs
mount -o loop $RPATH /mnt/ubuntu24.04/rootfs
rm /mnt/ubuntu24.04/rootfs/etc/resolv.conf
ln -s /proc/net/pnp /mnt/ubuntu24.04/rootfs/etc/resolv.conf
cp -v ../id_rsa.pub /mnt/ubuntu24.04/rootfs/root/.ssh/authorized_keys
mkdir -p /mnt/ubuntu24.04/rootfs/usr/local/bin
cp -v ../examiner /mnt/ubuntu24.04/rootfs/usr/local/bin/examiner
mkdir -p /mnt/ubuntu24.04/rootfs/opt/synnefo-labs/examiner/checks.d
cp -v ../opt/synnefo-labs/examiner/checks.d/test-container /mnt/ubuntu24.04/rootfs/opt/synnefo-labs/examiner/checks.d/
cp -v ../opt/synnefo-labs/examiner/checks.d/docker1 /mnt/ubuntu24.04/rootfs/opt/synnefo-labs/examiner/checks.d/
cp -v ../opt/synnefo-labs/examiner/checks.d/docker2 /mnt/ubuntu24.04/rootfs/opt/synnefo-labs/examiner/checks.d/
mkdir -p /mnt/ubuntu24.04/rootfs/etc/systemd/system
cp -v ../examiner.service /mnt/ubuntu24.04/rootfs/etc/systemd/system/examiner.service
ln -s /etc/systemd/system/examiner.service /mnt/ubuntu24.04/rootfs/etc/systemd/system/multi-user.target.wants/examiner.service

# Build readonly fs
mkdir -p /mnt/ubuntu24.04/rootfs/overlay/root \
 /mnt/ubuntu24.04/rootfs/overlay/work \
 /mnt/ubuntu24.04/rootfs/mnt \
 /mnt/ubuntu24.04/rootfs/rom

cp ../overlay-init /mnt/ubuntu24.04/rootfs/sbin/overlay-init

chmod +x /mnt/ubuntu24.04/rootfs/sbin/overlay-init
chown root:root /mnt/ubuntu24.04/rootfs/sbin/overlay-init

mksquashfs /mnt/ubuntu24.04/rootfs "$SCRIPT_DIR/rootfs.ext4" -noappend

umount /mnt/ubuntu24.04/rootfs
