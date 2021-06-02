import config
import logs
import json
import os
import osproc
import posix
import strutils

import util
import gateway

const
  curlLE = "curl --silent "
  providers = "/etc/bitmask/providers"
  curl = "curl --cacert " & providers & "/$#/ca.crt --silent "
  crt = providers & "/$#/ca.crt"

template getURL*(url: string): string =
  let provider = getProvider()
  let capth = providers & "/$#/ca.crt" % [provider,]
  if not fileExists(capth):
    echo("ERROR missing ca.crt, fetching files will fail")
  var cmd = curl % [provider,]
  if useTor():
    debug("Fetching with Tor")
    cmd = "torsocks " & cmd
  execProcess(cmd & $url)

template getExternalURL*(url: string): string =
  execProcess(curlLE & url)

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

proc getGateways*(url: string): seq[Gateway] =
  let j = getJson(url)
  var eipGateways = newSeq[Gateway](0)
  let gws = j{"gateways"}
  let locations = j{"locations"}
  try:
    for gw in gws:
      var locName = gw["location"].getStr()
      if locName == "new york city":
        # workaround, bad capitalization in eip-service!!!
        locName = "New York City"

      let loc = locations[locName]
      gw.add("cc", loc{"country_code"})
      gw.add("hemisphere", loc{"hemisphere"})
      gw.add("locationName", loc{"name"})
      var GW = to(gw, Gateway)
      eipGateways.add(GW)
  except:
    echo "ERROR exception parsing eip-service v3..."
    try:
      for gw in gws:
        # calyx gives no locations
        let g = to(gw, GatewayV1)
        let gw2 = Gateway(host: g.host, ip_address: g.ip_address)
        eipGateways.add(gw2)
    except:
      warn("failed to parse gateway!!")
      echo getCurrentExceptionMsg()
  result = eipGateways
