import algorithm
import asyncdispatch
import locks
import os
import osproc
import posix
import strutils
import strformat
import sugar
import syslog
import system

import threadproxy

import checks
import config
import curl
import management
import metrics

syslog.openlog("bitmask", logUser)

const pollPeriod = 1000

type
  Transport = object
    `type`*: string
    protocols*: seq[string]
    ports*: seq[string]

  Capabilities = object
    adblock: bool
    filter_dns: bool
    limited: bool
    user_ips: bool
    transport*: seq[Transport]

  Gateway* = object
    location*: string
    ip_address*: string
    host: string
    capabilities*: Capabilities

  GatewayV1 * = object
    ip_address*: string
    host: string

  Location* = object
    country_code: string
    hemisphere: char
    name: string
    timezone: string

type
  OpenVpnState {.pure.} = enum
    OFF,
    CONNECTING,
    WAIT,
    AUTH,
    GET_CONFIG,
    ASSIGN_IP,
    ADD_ROUTES,
    CONNECTED,
    RECONNECTING,
    EXITING,
    RESOLVE,
    TCP_CONNECT

  EIPState {.pure.} = enum
    OFF,
    CONNECTING,
    ON,
    DISCONNECTING,
    FAILED

var vpnLock*: Lock
initLock(vpnLock)
var openvpnProc {.threadvar.}: Process
var gateway {.threadvar.}: Gateway

proc releaseVpnLock(): void =
  if not openvpnProc.running:
    openvpnProc.close()
  try:
    vpnLock.release()
  except:
    discard

proc strToVPN(stateStr: string): OpenVPNState =
  result = parseEnum[OpenVpnState](stateStr)

proc strToEIP(stateStr: string): EIPState =
  case stateStr
  of $OpenVPNState.CONNECTING: result = EIPState.CONNECTING
  of $OpenVPNState.WAIT:       result = EIPState.CONNECTING
  of $OpenVPNState.GET_CONFIG: result = EIPState.CONNECTING
  of $OpenVPNState.ASSIGN_IP:  result = EIPState.CONNECTING
  of $OpenVPNState.ADD_ROUTES: result = EIPState.CONNECTING
  of $OpenVPNState.CONNECTED:  result = EIPState.ON
  of $OpenVPNState.EXITING:    result = EIPState.DISCONNECTING
  else: result = EIPstate.CONNECTING


proc getCommandFor*(gw: Gateway): string =
    let remote = gw.ip_address
    var port = ""
    try:
      port = gw.capabilities.transport[0].ports[0]
    except:
      port = "443"

    let ca = getCaPath()
    result = fmt"openvpn --client --dev tun --remote-cert-tls server --tls-client --remote {remote} {port} udp --remote {remote} {port} tcp --verb 3 --auth SHA1 --cipher AES-128-CBC --keepalive 10 30 --tls-version-min 1.0 --tls-cipher DHE-RSA-AES128-SHA --ca $# --cert /dev/shm/leap.crt --key /dev/shm/leap.crt --persist-key --persist-local-ip --management 127.0.0.1 6061 --redirect-gateway" % [ca,]

# --log /tmp/bitmask-openvpn.log"
# this only for testing on debian
# --script-security 2 --up /etc/openvpn/update-resolv-conf --down /etc/openvpn/update-resolv-conf --down-pre 

proc getGateways(url: string): seq[Gateway] =
  let j = getJson(url)
  var eipGateways = newSeq[Gateway](0)
  let gws = j{"gateways"}
  try:
    for gw in gws:
      eipGateways.add(to(gw, Gateway))
  except:
    try:
      for gw in gws:
        # calyx gives no locations
        let g = to(gw, GatewayV1)
        let gw2 = Gateway(host: g.host, ip_address: g.ip_address)
        eipGateways.add(gw2)
    except:
      echo "WARN failed to parse gateway!!"
      echo getCurrentExceptionMsg()
  result = eipGateways

proc listLocations(): seq[string] =
   var l = newSeq[string]()
   let eipUrl = getEipUrl()
   let gws = getGateways(eipUrl)
   for g in gws:
     if g.location notin l:
       l.add(g.location)
   l.sort()
   return l

proc getAutoGateway(): Gateway {.gcsafe.} =
  if gateway.host != "":
    return gateway

  let eipUrl = getEipUrl()
  let menshenUrl = getMenshenUrl()
  if menshenUrl != "":
    let
      j    = getJson(menshenUrl)
      city = j["city"].getStr()
      cc   = j["cc"].getStr()

    echo "INFO Your city appears to be $# ($#)" % [city, cc]
    let best = j["gateways"][0].getStr()
    let gws = getGateways(eipUrl)
    for g in gws:
      if g.host == best:
        echo "INFO Got automatic gateway: " & $g.host & " ($#)" % [$g.location,]
        return g
  else:
    echo "DEBUG No menshen, selecting first gateway"
    let gws = getGateways(eipUrl)
    if len(gws) == 0:
      echo "FATAL received zero gatways"
      quit()
    let g = gws[0]
    echo "INFO Selected gateway: " & g.host
    return g

proc manualGateway(gws: seq[Gateway], preferred: string): Gateway =
    for i in 0 .. len(gws)-1:
      if gws[i].location == preferred:
        let gw = gws[i]
        return gw
    raise newException(ValueError, "Gateway choice not found")

proc pickGatewayByLocation*(gw: string): vpn.Gateway {.gcsafe.} =
  let eipUrl = getEipUrl()
  let gws = getGateways(eipUrl)
  return manualGateway(gws, gw)

proc onDied(fd: AsyncFD): bool =
  # XXX use a global and watch it from state loop?
  syslog.debug("vpn died!")
  releaseVpnLock()
  return true

proc canStartVpn(): bool =
  if int(getuid()) != 0:
    echo "ERROR need to be run as root"
    return false
  return true

proc runVPNProc*(command: string): bool {.gcsafe.} =
  let canRun = vpnLock.tryAcquire()
  if not canRun:
    echo("WARN: cannot start vpn: locked")
    return false
  echo "DEBUG " & $command
  try:
    let p = command.startProcess(options={poEvalCommand, poStdErrToStdOut})
    openvpnProc = p
    syslog.debug("watching $#" % [$processID(p)])
    addProcess(processID(p), onDied)
  except:
    echo "ERROR cannot launch openvpn"

proc getCert(certUrl, caUrl: string) {.async.} =
  dump("/dev/shm/leap.crt", getURL(certUrl))

proc doInitVPN() =
  parseConfig()
  getCACrt()
  gateway = getAutoGateway()
  # TODO we can fetch certs here already
  echo "DEBUG Init done"

proc workerVPN*(proxy: ThreadProxy) {.thread.} =
  var mng: Manager
  var eipSt: EIPState
  var vpnSt: OpenVpnState
  var locations: seq[string]
  var metrics: MetricsRef
  var isReady: bool
  var timers: bool
  var count = 0

  proc parseState(str: string) =
    let vpn = strToVPN(str)
    let eip = strToEIP(str)
    if vpn != vpnSt:
      vpnSt = vpn
      eipSt = eip

  proc fetchStatus(fd: AsyncFD): bool {.gcsafe.} =
    if not isReady:
      return
    try:
      parseState(mng.getState.state)
    except:
      if mng.isTerminated():
        vpnSt = OpenVpnState.OFF
        eipSt = EIPState.OFF
      else:
        vpnSt = OpenVpnState.OFF
        eipSt = EIPState.FAILED

  proc collectMetrics(fd: AsyncFD): bool {.gcsafe.} =
    if eipSt != EIPState.ON:
      return
    callSoon(() => metrics.checkExitIP())
    callSoon(() => metrics.doPing())

  proc getManager(fd: AsyncFD): bool =
    while true:
      try:
        mng = connectToManagement()
        isReady = true
        break
        #echo "DEBUG " & $mng.getVersion()
      except:
        echo "ERROR cannot get manager!"
      sleep(200)

  proc doStart(fd: AsyncFD): bool {.gcsafe.} =
    # in case locations have changed in the meantime
    parseConfig()
    let prov = getProvider()
    echo "INFO provider:" & $prov
    # TODO check if we still have valid certs
    let certUrl = getCertUrl()
    let caUrl = getCaUrl()
    waitFor getCert(certUrl, caUrl)
    var gw: Gateway
    if isAuto():
      gw = getAutoGateway()
      echo "INFO Using auto gateway: " & $gw.host
    else:
      let loc = getLocation()
      gw = pickGatewayByLocation(loc)
      echo "INFO Using preferred location: " & $loc
      echo "INFO Selected gateway: " & $gw.host

    let cmd = getCommandFor(gw)
    let ok = runVPNProc(cmd)

    addTimer(int(pollPeriod * 5), true, getManager)
    # XXX need a way to cancel these timers...
    if not timers:
      metrics = MetricsRef()
      addTimer(int(pollPeriod), false, fetchStatus)
      addTimer(int(pollPeriod * 60), false, collectMetrics)
      timers = true

  proc doStop(fd: AsyncFD): bool {.gcsafe.} =
    #echo "type " & $typeof(mng) & $typeof(mng.terminated)
    try:
      if not mng.isTerminated():
        mng.doTerminate
        #releaseVpnLock()
    except:
      discard

  proxy.onData "start":
    if not canStartVpn():
      return %* {"start": "error"}
    addTimer(50, true, doStart)
    # FIXME return error if already started
    return %* {"start": "ok"}

  proxy.onData "stop":
    addTimer(50, true, doStop)
    return %* {"stop": "ok"}

  proxy.onData "status":
    echo "vpn: " & $vpnSt
    return %* {"status": $eipSt}

  proxy.onData "gwlocations":
    return %* {"gwlocations": $locations}

  # dummy command for debugging channels, can be removed
  proxy.onData "count":
    echo "count: " & $count
    inc count
    return %* {"count": $count}

  mng = dummyManager()
  if not checkForManagement():
    echo "ERROR (fatal) you need to install an openvpn variant with management interface enabled"
    quit()
  else:
    echo "DEBUG OpenVPN has management interface, good"
  checkForRoot()
  doInitVPN()
  locations = listLocations()
  waitFor proxy.poll()
