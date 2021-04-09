import syslog

syslog.openlog("bitmask", logUser)

proc debug*(msg: string)=
        syslog.debug(msg)

proc info*(msg: string)=
        syslog.info(msg)

proc error*(msg: string)=
        syslog.error(msg)
