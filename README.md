# Bitmask for OpenWRT

A LEAP-VPN client for embedded devices. Works with RiseupVPN and CalyxVPN for the time being.

![router](https://0xacab.org/kali/bitmask-openwrt/-/raw/master/docs/router.png)

## Supported devices

The project is still not mature, so expect things to break. The following OpenWRT routers are supported :

* GL-iNet MT-300M-V2
* GL-iNet AR-750

See [here](https://0xacab.org/kali/bitmask-openwrt/-/tree/master/docs/devices)
for more info and config files that you can use as a basis to build your own
images.

## Install

If you want to help testing, please follow these steps from your router:

### 1. Add kali's feed to your `/etc/opkg/customfeeds.conf`

For `ar-750`:

```
src leap https://sindominio.net/kali/openwrt/packages/mips_24kc/leap
src leap-openwrt https://sindominio.net/kali/openwrt/packages/mips_24kc/packages/
```

For `mt-300m-v2`:

```
src leap https://sindominio.net/kali/openwrt/packages/mipsel_24kc/leap
src leap-openwrt https://sindominio.net/kali/openwrt/packages/mipsel_24kc/packages/
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


## Cross-compile packages

* Get a recent 👑 [nim](https://nim-lang.org/) version (use `choosenim`).
* From the top of your [OpenWRT SDK](https://github.com/openwrt/openwrt/), do:

```
git clone https://0xacab.org/kali/bitmask-openwrt ../bitmask-openwrt
ln -s ../bitmask-openwrt package/bitmask-vpn
make package/bitmask-vpn/{clean,compile}
```

* Package will be ready under `bin/packages`:

```
bin/packages/mipsel_24kc/base/bitmask-vpn_0.0.1-1_mipsel_24kc.ipk
```

[Here](https://0xacab.org/kali/bitmask-openwrt/-/tree/master/docs/build-packages.md) is the whole story.

## Run

Until the package is a bit more polished (daemon, logs etc), you can run things manually from a tmux screen or similar:

```
DEBUG=2 /usr/bin/bitmaskd
```

The supported models can be controlled with the toggle button (A symlink should
be created in `/etc/rc.button/BTN_0` on the first run). One of the leds will be
toggled on/off to indicate the status of the tunnel.

Alternatively, for the time being you can control the connection via the REST API:

```
# with curl, locally from the router
curl localhost:8080/start
curl localhost:8080/status
curl localhost:8080/stop
```

You will see logs in the standard output.

## Routing and DNS leak prevention

Work in progress. Please do [read this](https://0xacab.org/kali/bitmask-openwrt/-/tree/master/docs/routing.md)
for pointers. Contributions welcome!

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

### Use Tor

If you have `tor` and `torsocks` installed in the router, you can use the Tor network to fetch configuration and certificates.

```
useTor=true
```

## Contributing

Would you like support for a particular device? Got a feature request? 
Please open an issue; merge requests and suggestions are welcome.

## Contact

This project is maintained by Kali Kaneko. I hang out in IRC (#leap and #bitmask-dev at libera.chat).
