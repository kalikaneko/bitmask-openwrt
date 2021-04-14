import json
import os
import osproc
import tables

import logs

# TODO when support grows, this module can be generated from a json.
# For the time being it is enough with defining switch and vpn leds.

const knownLEDS = {
  "gl-ar750": "/sys/devices/platform/leds-gpio/leds/gl-ar750:white:wlan5g/brightness"
}

var
  model {.threadvar.}: string
  leds {.threadvar.}: Table[string, string]

proc doInitBoard*() =
  let j = parseFile("/etc/board.json")
  model = j{"model"}{"id"}.getStr()
  leds = knownLEDS.toTable
  info("Board: " & $model)

proc ledStatusOn*() {.gcsafe.} =
  if model != "":
    writeFile(leds[model], "255")

proc ledStatusOff*() {.gcsafe.} =
  if model != "":
    writeFile(leds[model], "0")

proc ledStatusConnecting*() =
  debug("leds: status connecting")

proc getButtonState*() =
  debug("button: get state")
