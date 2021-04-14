import json
import os
import tables

import logs

# TODO when support grows, this module can be generated from a json.
# For the time being it is enough with defining switch and vpn leds.

var
  model {.threadvar.}: string
  VPN_LED = {"gl-ar750": "/sys/devices/platform/leds-gpio/leds/gl-ar750:white:wlan5g/brightness"}.toTable()


proc doInitBoard*()=
  let j = parseFile("/etc/board.json")
  model = j{"model"}{"id"}.getStr()

  info("Board: " & $model)

proc signalStatusOn*() =
  debug("leds: status on")

proc signalStatusOff*() =
  debug("leds: status off")

proc signalStatusConnecting*() =
  debug("leds: status connecting")

proc getButtonState*() =
  debug("button: get state")
