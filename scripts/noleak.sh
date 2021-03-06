#!/bin/sh

if ( route|grep tun0 1>/dev/null ) || ( ip a s tun0 up 1>/dev/null ); then
	touch /etc/bitmask/openvpn.lock
        /etc/bitmask/scripts/dnsredir.sh
	if ( iptables -C forwarding_rule -j REJECT ); then
		iptables -D forwarding_rule -j REJECT
	fi
fi

if [ -e /etc/bitmask/openvpn.lock ]; then
	if (! route|grep tun0 1>/dev/null ) || (! ip a s tun0 up 1>/dev/null ); then
		if (! iptables -C forwarding_rule -j REJECT); then
			iptables -I forwarding_rule -j REJECT
		fi
	fi
fi

exit 0
