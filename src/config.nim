import parsecfg
import strutils
import strformat
import os
import posix

import util

const
  START* = "start"
  STOP* = "stop"
  STATUS* = "status"
  GWLOCATIONS* = "gwlocations"
  GWLOCATIONSJSON* = "gwlocationsjson"
  LOCATIONSET* = "locationset"
  GETIP* = "getip"

const
  CONFIG = "bitmask.cfg"
  SYSDIR = "/etc/bitmask"
  VPNDIR = "/etc/openvpn"
  DEFAULT_PROVIDER = "riseup"
  DEFAULT_API = "https://api.black.riseup.net/"
  DEFAULT_MENSHEN = "https://api.black.riseup.net:9001/json"
  DEFAULT_CA="https://black.riseup.net/ca.crt"

const wtfIpUrl* = "https://wtfismyip.com/json"

var location {.threadvar.}: string
var autoSel {.threadvar.}: bool
var tor {.threadvar.}: bool
var service {.threadvar.}: bool
var provider{.threadvar.}: string
var providerApi{.threadvar.}: string
var menshenUrl{.threadvar.}: string
var caUrl{.threadvar.}: string


proc getProvider*(): string =
  var p = DEFAULT_PROVIDER
  if provider != "":
      p = provider
  return p

proc setProvider(value: string) =
  provider = value

proc getProviderApi*(): string =
  var a = DEFAULT_API
  if providerApi != "":
      a = providerApi
  return a

proc setProviderApi(value: string) =
  providerApi = value

proc getCaUrl*(): string =
  var c = DEFAULT_CA
  if caUrl != "":
    c = caUrl
  return c

proc setCaUrl(value: string) =
  caUrl = value

proc getCertUrl*(): string =
  return getProviderApi() & "/1/cert"

proc getCaPath*(): string =
  return SYSDIR & "/providers/" & getProvider() & "/ca.crt"

proc getEipUrl*(): string =
  # FIXME use api v3, write unit test
  return getProviderApi() & "/1/config/eip-service.json"

proc getMenshenUrl*(): string =
  return menshenUrl

proc setMenshenUrl(value: string) =
  menshenUrl = value

proc setAuto*(value: bool) =
  autoSel = value

proc isAuto*(): bool =
  return autoSel

proc setLocation*(value: string) =
  # setting one location switches to manual mode,
  # auto needs to be selected explicitely
  setAuto(false)
  location = value

proc getLocation*(): string =
  return location 

proc useTor*(): bool =
  return tor

proc setTor(value: bool) =
  tor = value

proc useService*(): bool =
  return service

proc setService(value: bool) =
  service = value

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
  c.setSectionKey("Providers","default",DEFAULT_PROVIDER)
  c.setSectionKey("Providers","api", DEFAULT_API)
  c.setSectionKey("Providers","menshen", DEFAULT_MENSHEN)
  c.writeConfig(pth)

proc getOrCreateConfig(): Config =
  let syscfg = SYSDIR & "/" & CONFIG

  if fileExists(CONFIG):
    return loadConfig(CONFIG)

  if fileExists(syscfg):
    return loadConfig(syscfg)

  if isRoot():
    createDir(SYSDIR)
    createDir(SYSDIR & "/providers")
    writeSampleConfig(syscfg)
    return loadConfig(syscfg)

  writeSampleConfig(CONFIG)
  return loadConfig(CONFIG)

proc parseConfig*() =
  let d = getOrCreateConfig()
  let Providers = "Providers"
  let Locations = "Locations"
  var preferred = d.getSectionValue(Locations,"preferred")
  if preferred != "":
    setLocation(preferred)
  var provider = d.getSectionValue(Providers, "default")
  if provider != "":
     setProvider(provider)
  var ca = d.getSectionValue(Providers, "ca")
  if ca != "":
     setCaUrl(ca)
  var api = d.getSectionValue(Providers, "api")
  if api != "":
     setProviderApi(api)
  var menshen = d.getSectionValue(Providers, "menshen")
  if menshen != "":
     setMenshenUrl(menshen)
  var selAuto = toBool(d.getSectionValue(Locations,"auto", "true"))
  var tor = toBool(d.getSectionValue("", "useTor", "false"))
  setTor(tor)

  var useService = toBool(d.getSectionValue("", "useService", "false"))
  setService(useService)

  if (not selAuto and preferred == ""):
    echo "ERROR if auto is set to false, I need a preferred location"
  setAuto(selAuto)

proc dumpServiceConfig*(provider, cfg: string) =
  let pth = VPNDIR & "/" & provider & ".ovpn"
  dumpFile(pth, cfg)
  # TODO avoid duplicate
  let vpnCfg = fmt"""package openvpn

config openvpn {provider}
    option enabled 1
    option config {pth}"""
  dumpFile("/etc/config/openvpn", vpnCfg)

