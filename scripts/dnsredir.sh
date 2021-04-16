#!/bin/sh
# DNSREDIR
# Log and redirect DNS Traffic

# TODO: this need to change for UDP
NAMESERVER_TCP="10.41.0.1"

iptables -t nat -N dnsredir
iptables -t nat -I dnsredir -j LOG --log-prefix "dnsredir "
iptables -t nat -A dnsredir -j DNAT --to-destination $NAMESERVER_TCP

# anything else is hijacked
iptables -t nat -A prerouting_lan_rule -p udp --dport 53 -j dnsredir
iptables -t nat -A prerouting_lan_rule -p tcp --dport 53 -j dnsredir

# fix "reply from unexpected source"
iptables -t nat -A postrouting_lan_rule -d $NAMESERVER_TCP -p tcp -m tcp --dport 53 -m comment --comment "!fw3: DNS BitmaskVPN MASQUERADE" -j MASQUERADE
iptables -t nat -A postrouting_lan_rule -d $NAMESERVER_TCP -p udp -m udp --dport 53 -m comment --comment "!fw3: DNS BItmaskVPN MASQUERADE" -j MASQUERADE

