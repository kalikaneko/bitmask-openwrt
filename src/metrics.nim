import json
import osproc
import re
import strutils

const geoipCmd = "curl --silent https://wtfismyip.com/json"
const pingCmd: string = "ping -c 3 -4 http.debian.net"

# should collapse metrics in a map from ip to metrics average or similar,
# so that we can stablish a baseline.

type
  Metrics = object
    ip: string
    country_code: string
    ping_loss: int
    ping_avg: float32
  MetricsRef* = ref Metrics

proc checkExitIP*(m: MetricsRef) =
  try:
    let jstr = execProcess(geoipCmd).replace("\n")
    let parsed = parseJson(jstr)
    m.ip = parsed["YourFuckingIPAddress"].getStr()
    m.country_code = parsed["YourFuckingCountryCode"].getStr()
    echo "IP: $# ($#)" % [m.ip, m.country_code]
  except:
    discard ""

proc doPing*(m: MetricsRef) =
  # FIXME this does not match busybox ping
  let ping = execProcess(pingCmd)
  for line in splitLines(ping):
    if "%" in line:
      let loss = re.findAll(line, re"(\d+)%")[0]
      m.ping_loss = parseInt(loss.split('%')[0])
    elif "rtt" in line:
      let stats = re.findAll(line, re"\d+.\d+/\d+.\d+/\d+.\d+/\d+.\d+")[0]
      m.ping_avg = parseFloat(stats.split('/')[1])

  echo "ping: avg $# ms ($# loss)" % [
    float(m.ping_avg).formatFloat(ffDecimal, 2),
    float(m.ping_loss).formatFloat(ffDecimal, 2)]
