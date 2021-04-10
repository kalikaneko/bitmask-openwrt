Configuration
=============

Setting up a custom provider
----------------------------

Use this in your `/etc/bitmask/bitmask.cfg` to use a different LEAP provider.
In this case we configure the Calyx Institute provider, which has a single
gateway:

```
[Providers]
default=calyx
api="https://api.calyx.net:4430"
ca="https://calyx.net/ca.crt"
```


