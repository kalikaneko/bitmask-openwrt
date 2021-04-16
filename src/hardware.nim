import json
import posix
import os
import osproc
import streams
import strutils
import tables

import logs

# TODO when support grows, this module can be generated from a json.
# For the time being it is enough with defining switch and vpn leds.

const knownLEDS = {
  "gl-ar750": "/sys/devices/platform/leds-gpio/leds/gl-ar750:white:wlan5g/brightness",
  "gl-mt300n-v2": "/sys/devices/platform/leds/leds/gl-mt300n-v2:green:wan/brightness"
}

const knownBUTTONS = {
  "gl-ar750": "sw1",
  "gl-mt300n-v2": "gpio-0"
}

const kernelGpio = "/sys/kernel/debug/gpio"
const systemButton = "/etc/rc.button/BTN_0"
const buttonScript = "/etc/bitmask/scripts/BTN_0"
const systemBoard = "/etc/board.json"

var
  model {.threadvar.}: string
  leds {.threadvar.}: Table[string, string]
  button {.threadvar.}: Table[string, string]

proc symlinkScripts() =
  var dolink = false
  if fileExists(buttonScript):
    if not fileExists(systemButton):
      dolink = true
    else:
      let ours = execProcess("grep -c LEAP " & systemButton).strip
      if ours == "1":
          dolink = true
      else:
        warn(r"""There is an existing script at $#, I prefer not to overwrite it.
     If you want full hardware support, you might want to manually symlink it:
     cp /etc/rc.button/BTN_0 /etc/rc.button/BTN_0.OLD
     ln -s $# $#""" % [systemButton, buttonScript, systemButton])
  if dolink:
    if fileExists(systemButton):
      discard tryRemoveFile(systemButton)
    createSymlink(buttonScript, systemButton)
    discard chmod(systemButton, 448)

proc doInitBoard*() =
  let j = parseFile(systemBoard)
  model = j{"model"}{"id"}.getStr()
  leds = knownLEDS.toTable
  button = knownBUTTONS.toTable
  info("Board: " & $model)
  symlinkScripts()

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
