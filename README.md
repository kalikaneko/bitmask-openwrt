# Bitmask for OpenWRT

A LEAP-VPN client for embedded devices. Works with RiseupVPN, for the time
being, but it should be easy to configure for other providers.

## Supported devices

The project is still not mature, so expect things to break. The following OpenWRT routers are supported :

* GL-iNet 300M V2
* GL-iNET AR750

If you want to help testing, for now, you can fetch packages manually from [here](https://sindominio.net/kali/openwrt/mipsel_24kc/packages/).

## Dependencies

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

## Cross-compile

You will need a recent 👑 [nim](https://nim-lang.org/) version (use `choosenim`) and [upx](https://upx.github.io/) in your host.

Then, from the top of your [OpenWRT SDK](https://github.com/openwrt/openwrt/), do:

```
git clone https://0xacab.org/kali/bitmask-openwrt ../bitmask-openwrt
ln -s ../bitmask-openwrt package/bitmask-vpn
make package/bitmask-vpn/compile
```

Package should be ready under `bin/packages`:

```
bin/packages/mipsel_24kc/base/bitmask-vpn_0.0.1-1_mipsel_24kc.ipk
```

Do note, though, that you need to compile a version of openvpn with management
support enabled. `make menuconfig` is your friend. I want to provide custom
feeds to make installation more user-friendly in the future.

## Run

Until the packagte is a bit more polished (daemon, logs etc), you can run things manually from a tmux screen or similar:

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
