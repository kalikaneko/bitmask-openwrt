Create feed
===========
Check out https://openwrt.org/docs/guide-developer/build-system/use-buildsystem

From the top of your OpenWRT tree:

```
git clone https://0xacab.org/kali/bitmask-openwrt ../bitmask-openwrt
echo "src-link `pwd`/leap_packages" >> feeds.conf.default
mkdir -p leap_packages/net/network
ln -s `pwd`/../bitmask-openwrt leap_packages/net/network/bitmask-vpn
./scripts/feeds update -a
./scripts/feeds install bitmask-vpn
```

Compile
=======

```
make package/bitmask-vpn/compile
```

Build image
===========
You can build a flashable image:

```
wget .../AR750.config -O .config
make -j$(($(nproc)+1))
```
