import config
import logs
import json
import os
import osproc
import posix
import streams
import strutils

import util

const
  curlLE = "curl --silent "
  providers = "/etc/bitmask/providers"
  curl = "curl --cacert " & providers & "/$#/ca.crt --silent "
  crt = providers & "/$#/ca.crt"

template getURL*(url: string): string =
  let provider = getProvider()
  var cmd = curl % [provider,]
  if useTor():
    debug("Fetching with Tor")
    cmd = "torsocks " & cmd
  execProcess(cmd & $url)

proc getJson*(url: string): JSonNode =
  var str = getURL(url)
  str = str.replace("\n")
  parseJson(str)

proc isRoot(): bool =
  return int(getuid()) == 0

proc getCACrt*() =
  let provider = getProvider()
  let crtPath = crt % [provider,]
  if not fileExists(crtPath):
    if isRoot():
      createDir(providers & "/$#" % [provider,])
    let caUrl = getCaUrl()
    echo "DEBUG geting " & caUrl
    echo "DEBUG writing ca.crt to " & $crtPath
    dumpFile(crtPath, execProcess(curlLE & $caUrl))
