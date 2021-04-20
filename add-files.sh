#!/bin/bash
# ----------------------------------------------------------------
# This script adds binaries into a flashable image.
# It is mostly a workaround because I didn't find how to make the
# ipk to actually install during the image building process.
# ----------------------------------------------------------------

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TODO get this from package
# TODO get this from .config
VERSION=0.0.1
TARGET=${TARGET-mipsel_24kc_musl}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

rm -rf files/usr/bin/bitmaskd
rm -rf files/etc/bitmask
mkdir -p files/usr/bin/
mkdir -p files/etc/bitmask
cp build_dir/target-${TARGET}/bitmask-vpn-${VERSION}/bitmaskd files/usr/bin/
cp -r build_dir/target-${TARGET}/bitmask-vpn-${VERSION}/providers files/etc/bitmask/
cat <<EOF > files/etc/resolv.conf
nameserver 213.73.91.35
nameserver 127.0.0.1
nameserver ::1
EOF
