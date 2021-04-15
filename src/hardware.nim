import json
import os
import streams
import strutils
import tables

import logs

# TODO when support grows, this module can be generated from a json.
# For the time being it is enough with defining switch and vpn leds.

const knownLEDS = {
  "gl-ar750": "/sys/devices/platform/leds-gpio/leds/gl-ar750:white:wlan5g/brightness"
}

const knownBUTTONS = {
  "gl-ar750": "sw1"
}

const kernelGpio = "/sys/kernel/debug/gpio"

var
  model {.threadvar.}: string
  leds {.threadvar.}: Table[string, string]
  button {.threadvar.}: Table[string, string]

proc doInitBoard*() =
  let j = parseFile("/etc/board.json")
  model = j{"model"}{"id"}.getStr()
  leds = knownLEDS.toTable
  button = knownBUTTONS.toTable
  info("Board: " & $model)

proc ledStatusOn*() {.gcsafe.} =
  if model != "":
    writeFile(leds[model], "255")

proc ledStatusOff*() {.gcsafe.} =
  if model != "":
    writeFile(leds[model], "0")

proc ledStatusConnecting*() =
  # TBD
  debug("leds: status connecting")

proc readButton(path, id: string): string =
  for line in newStringStream(readFile(path)).lines:
    if contains(line, id):
      let p = line.strip().split(" ")
      return p[p.len-1]

proc isButtonON*(): bool =
  let b = readButton(kernelGpio, button[model])
  if b == "hi":
    return true
  elif b == "lo":
    return false
  bug("cannot read button")
  return false
