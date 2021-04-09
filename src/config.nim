import parsecfg
import strutils
import os
import posix

const CONFIG = "bitmask.cfg"
const SYSDIR = "/etc/bitmask"

var location {.threadvar.}: string
var autoSel {.threadvar.}: bool

proc setLocation*(value: string) =
  location = value

proc getLocation*(): string =
  return location 

proc setAuto*(value: bool) =
  autoSel = value

proc isAuto*(): bool =
  return autoSel

proc toBool(v: string): bool =
  case v.toLowerAscii
  of "true":
    return true
  of "1":
    return true
  of "yes":
    return true
  of "y":
    return true
  return false

proc isRoot(): bool =
  return int(getuid()) == 0

proc writeSampleConfig(pth: string) =
  var c=newConfig()
  c.setSectionKey("Locations","auto","true")
  c.writeConfig(pth)

proc getOrCreateConfig(): Config =
  let syscfg = SYSDIR & "/" & CONFIG

  if fileExists(CONFIG):
    return loadConfig(CONFIG)

  if fileExists(syscfg):
    return loadConfig(syscfg)

  if isRoot():
    createDir(SYSDIR)
    writeSampleConfig(syscfg)
    return loadConfig(syscfg)

  writeSampleConfig(CONFIG)
  return loadConfig(CONFIG)

proc parseConfig*() =
  let d = getOrCreateConfig()
  var selAuto = toBool(d.getSectionValue("Locations","auto", "true"))
  var preferred = d.getSectionValue("Locations","preferred")
  if preferred != "":
    setLocation(preferred)
  if (not selAuto and preferred == ""):
    echo "ERROR if auto is set to false, I need a preferred location"
  setAuto(selAuto)
