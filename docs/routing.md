Routing
=======

Ok, I have RiseupVPN running, now what?

Having a VPN in your own router with OpenWRT can give you great flexibility,
but with great flexibility also comes great responsibility :)

It doesn't seem polite to mess too much with how you want to configure your
things in **your** router, but at the same time one of the main goals of
Bitmask/RiseupVPN is to provide users a zero-config experience.

To achieve that, this project will provide pre-configured images with sensible
configurations that can get you running. In the meantime, here are some tips:

# Add a new interface

In `/etc/config/network` we create a new interface for the tun0 device:

```
config interface 'leapvpntun'
	option ifname 'tun0'
	option proto 'none'
```

# Add a new firewall zone 

Now in `/etc/config/firewall` we can add a new zone associated with the network
that will be created for the tunnel.

```
config zone
	option name		leapfw
	list network		leapvpntun
	option input 		REJECT
	option output   	ACCEPT
	option output   	ACCEPT
	option forward  	REJECT
	option masq 		1
	option mtu_fix  	1

config forwarding
	option src 		lan
	option dest		leapfw
```

Here you can make sure that this "forwarding" block is the only one active. The
first targets for this package have physical buttons to enable or disable the
network, and we think it's safe to fail close and cut off all the access to the
clearnet if the tunnel fails.

# Preventing DNS leaks

You can avoid DNS leaks by getting some routing redirections added when the
tunnel is on. To achieve that, create the following symlink:

```
ln -s /etc/bitmask/scripts/99-noleak /etc/hotplug.d/iface/99-noleak
```

Please do note that this is not battle tested yet, so please don't rely on this
package if that is going to put you -or the users of your router- in risk. If
you find problems please get in touch.
