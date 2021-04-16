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
You can build a flashable image with:

```
wget .../AR750.config -O .config
make download
make -j$(($(nproc)+1)) world
```

Size optimizations
==================

Optionally, you can use [upx](https://upx.github.io/) in your host to reduce the binary size. Note that upx 3.96 seems to have [a bug with mipsel](https://github.com/upx/upx/issues/87), use [3.93](https://github.com/upx/upx/releases/download/v3.93/upx-3.93-amd64_linux.tar.xz) instead.

It might be wrong, but I was observing that the compressed binary was performing very poorly in my hardware. Since size constrains are not a huge requirement at this stage, I've disabled the upx step in the Makefile.

When the time comes to put this into a tinier routers, I might explore upx again, because on my initial tests I was very impressed by the compression factor. Or, to be honest, maybe one can do with just the vanilla OpenWRT package and some shell scripts. All this boilerplate is only nice if you have plenty of space, and if you plan to do fancier things in the future (like a slick web interface ;)
