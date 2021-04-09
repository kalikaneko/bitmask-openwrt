import json
import strutils
import os
import osproc
import streams

const
  curl = "curl --cacert /etc/bitmask/riseup.crt --silent "
  curlLE = "curl --silent "
  crt = "/etc/bitmask/riseup.crt"
  crtUrl = "https://black.riseup.net/ca.crt"

template getURL*(url: string): string =
  execProcess(curl & $url)

proc dump*(pth: string, data: string) =
  let s = newFileStream(pth, fmWrite)
  s.write(data)
  s.close()

proc getJson*(url: string): JSonNode =
  var str = getURL(url)
  str = str.replace("\n")
  parseJson(str)

proc getCACrt*() =
  if not fileExists(crt):
    echo "DEBUG writing ca.crt to " & $crt
    dump(crt, execProcess(curlLE & $crtUrl))
