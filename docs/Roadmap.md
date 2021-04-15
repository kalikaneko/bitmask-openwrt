Roadmap for Bitmask-OpenWRT 🚀
==============================

0.0.1
=====
* [x] initial OpenWRT package
* [x] support for MT300/AR750
* [x] simple rest api
* [x] ability to read config files
* [x] minimal branding to use riseup/calyx

0.1.0
=====
* [x] gateway selection
* [x] leds/buttons support
* [ ] autostart if switch on
* [ ] image builder
* [ ] ready-to-flash images
* [ ] beryl support

0.2.0
=====
* [ ] proper daemon / logs
* [ ] bitmaskctl util (symlinked to same binary)
* [ ] cli help 
* [ ] measure distance to gateways
* [ ] add password to telnet interface
* [ ] use unix domain socket for management
* [ ] init check for running openvpn
* [ ] tplink archer support

0.3.0
=====
* [ ] web interface 
* [ ] luci integration
* [ ] autostart (checks status)
* [ ] parse gw protocols (udp/pt)
* [ ] fix metrics for busyBox ping

0.4.0
=====
* [ ] killswitch: firewall/routing (use /etc/config/firewall)
* [ ] use uci config
* [ ] traffic stats
