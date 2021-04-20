#!/bin/bash
# ----------------------------------------------------------------
# This script adds binaries into a flashable image.
# It is mostly a workaround because I didn't find how to make the
# ipk to actually install during the image building process.
# ----------------------------------------------------------------

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
VERSION=0.0.1
TARGET=${TARGET-mipsel_24kc_musl}
# TODO get this from package
# TODO get this from .config
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

rm -rf files/usr/bin/bitmaskd
rm -rf files/etc/bitmask
mkdir -p files/usr/bin/
mkdir -p files/etc/bitmask
mkdir -p files/etc/config
mkdir -p files/etc/hotplug.d/iface/
mkdir -p files/etc/rc.button
touch files/etc/resolv.conf
cp build_dir/target-${TARGET}/bitmask-vpn-${VERSION}/bitmaskd files/usr/bin/
cp -r build_dir/target-${TARGET}/bitmask-vpn-${VERSION}/providers files/etc/bitmask/
cp -r build_dir/target-${TARGET}/bitmask-vpn-${VERSION}/scripts files/etc/bitmask/
cd files/etc/rc.button && rm -f BTN_0 && ln -s ../bitmask/scripts/BTN_0 . && cd ../../../
cd files/etc/hotplug.d/iface && rm -f 99-noleak && ln -s ../bitmask/scripts/99-noleak . && cd ../../../../
cd files/etc && rm -f firewall.user && ln -s bitmask/scripts/firewall.user . && cd ../../

# glinet-m300n-v2
cp ../bitmask-openwrt/config/firewall files/etc/config
cp ../bitmask-openwrt/config/network files/etc/config

cat <<EOF > files/etc/resolv.conf
nameserver 10.41.0.1
nameserver 208.67.222.222
nameserver 208.67.220.220
nameserver 127.0.0.1
nameserver ::1
EOF

echo "Extra files added to flash RiseupVPN router."
