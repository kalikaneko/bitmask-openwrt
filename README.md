# Bitmask for OpenWRT

A LEAP-VPN client for embedded devices. Works with RiseupVPN and CalyxVPN for the time being.

![router](https://0xacab.org/kali/bitmask-openwrt/-/raw/master/docs/router.png)

## Supported devices

The project is still not mature, so expect things to break. The following OpenWRT routers are supported :

* GL-iNet 300M V2
* GL-iNET AR750

See [here](https://0xacab.org/kali/bitmask-openwrt/-/tree/master/docs/devices)
for more info and config files that you can use as a basis to build your own
images.

## Install

If you want to help testing, please follow these steps from your router:

### 1. Add kali's feed to your `/etc/opkg/customfeeds.conf`

```
# for AR750
src leap https://sindominio.net/kali/openwrt/packages/mips_24kc/leap
```

### 2. Download and verify the developer key.

```
wget https://sindominio.net/kali/openwrt/key-build.pub
```

If you feel like using gpg to verify that signature, you can use:

```
wget https://sindominio.net/kali/openwrt/key-build.pub.asc
gpg --verify key-build.pub.asc
```

Now add the key to opkg's store:

```
opkg-key add key-build.pub
```

### 3. Update your feeds and install

(Note: you need TLS support enabled in wget at the moment, I have to move the feed somewhere that doesn't redirect to https).

```
opkg update
opkg install bitmask-vpn
```

If you had a previous version of openvpn-mbedtls you might want to uninstall it and get the one in kali's feed instead, since this one is compiled with management support.


## Development

```
# runtime
apt install openvpn

# compilation (host)
apt install nim
```

## Compile

```
cd src
make deps
make build
```

## Cross-compile packages

The quick-n-dirty way:

Get a recent 👑 [nim](https://nim-lang.org/) version (use `choosenim`) and [upx](https://upx.github.io/) in your host.

From the top of your [OpenWRT SDK](https://github.com/openwrt/openwrt/), do:

```
git clone https://0xacab.org/kali/bitmask-openwrt ../bitmask-openwrt
ln -s ../bitmask-openwrt package/bitmask-vpn
make package/bitmask-vpn/{clean,compile}
```

Package will be ready under `bin/packages`:

```
bin/packages/mipsel_24kc/base/bitmask-vpn_0.0.1-1_mipsel_24kc.ipk
```

See `docs/build-packages.md` for the whole story.

## Run

Until the package is a bit more polished (daemon, logs etc), you can run things manually from a tmux screen or similar:

```
# on one window
/usr/bin/bitmaskd

# on another, locally from the router
curl localhost:8080/start
curl localhost:8080/status
curl localhost:8080/stop
```

You will see logs in the standard output.

## Configure

You can configure the server adding options to `bitmask.cfg`, either on the
same folder as the binary, or in a system-wide folder in
`/etc/bitmask/bitmask.cfg`. 

You can select `auto` algorithm to select gateway, or pick your preferred exit
location.

```
[Locations]
auto=false
preferred=paris
```

You can get a list of valid locations with:

```
curl localhost:8080/locations
```

## Issues

Do note that, for the time being, *no firewall* is implemented. It's your
responsibility to properly secure your device and avoid leaks.

## Contributing

Would you like support for a particular device? Got a feature request? 
Please open an issue; merge requests and suggestions are welcome.

## Contact

This project is maintained by Kali Kaneko. I hang out in IRC (#leap and #bitmask-dev at freenode).
