import algorithm
import asyncdispatch
import locks
import os
import osproc
import posix
import strutils
import strformat
import sugar
import system

import threadproxy

import banner
import checks
import config
import curl
import gateway
import hardware
import logs
import management
import metrics
import util

const pollPeriod = 500


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
var gw {.threadvar.}: Gateway

proc startService(): void =
  # TODO check if running, then restart?
  discard execProcess("/etc/init.d/openvpn reload")
  discard execProcess("/etc/init.d/openvpn start")

proc stopService(): void =
  discard execProcess("/etc/init.d/openvpn stop")

proc releaseVpnLock(): void =
  if not openvpnProc.running:
    try:
     openvpnProc.close()
    except:
      warn("Could not close openvpn proc")
  try:
    vpnLock.release()
  except:
    debug("Cannot release lock")

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


proc getCommandFor*(gw: Gateway, oneline: bool=true): string =
    let remote = gw.ip_address
    var port = ""
    try:
      port = gw.capabilities.transport[0].ports[0]
    except:
      port = "443"

    let ca = getCaPath()
    var debugLevel = "3"
    let debug = getEnv("DEBUG")
    if debug != "":
      debugLevel = debug
    let udp = getEnv("UDP")
    var transport = "tcp"
    if udp == "1":
      transport = "udp"
    if oneline:
      result = fmt"openvpn --client --dev tun --remote-cert-tls server --tls-client --remote {remote} {port} {transport} --verb {debugLevel} --auth SHA1 --cipher AES-128-CBC --keepalive 10 30 --tls-version-min 1.2 --tls-cipher DHE-RSA-AES128-SHA --ca {ca} --cert /dev/shm/leap.crt --key /dev/shm/leap.crt --management 127.0.0.1 6061 --redirect-gateway --connect-retry 2 --connect-retry-max 10 --persist-tun"
      if debug != "":
        result = result & " --log /tmp/bitmask-openvpn.log"
    else:
      result = fmt"""client
dev tun
remote-cert-tls server
tls-client
remote {remote} {port} {transport}
verb {debugLevel}
auth SHA1
cipher AES-128-CBC
keepalive 10 30
tls-version-min 1.2
tls-cipher DHE-RSA-AES128-SHA
ca {ca}
cert /dev/shm/leap.crt
key /dev/shm/leap.crt
management 127.0.0.1 6061
redirect-gateway
connect-retry 2
connect-retry-max 10
persist-tun"""


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
  if gw.host != "":
    return gw 

  let eipUrl = getEipUrl()
  let menshenUrl = getMenshenUrl()
  if menshenUrl != "":
    let
      j    = getJson(menshenUrl)
      city = j["city"].getStr()
      cc   = j["cc"].getStr()
      #ip   = j["ip"].getStr()
      #lat  = j["lat"].getStr()
      #lon  = j["lon"].getStr()

    info("Your city appears to be $# ($#)" % [city, cc])
    let best = j["gateways"][0].getStr()
    let gws = getGateways(eipUrl)
    for g in gws:
      if g.host == best:
        echo "INFO Got automatic gateway: " & $g.host & " ($#)" % [$g.location,]
        return g
  else:
    debug("No menshen, selecting first gateway")
    let gws = getGateways(eipUrl)
    if len(gws) == 0:
      echo "FATAL received zero gatways"
      quit()
    let g = gws[0]
    info("Selected gateway: " & g.host)
    return g

proc manualGateway(gws: seq[Gateway], preferred: string): Gateway =
    for i in 0 .. len(gws)-1:
      if gws[i].location == preferred:
        let gw = gws[i]
        return gw
    raise newException(ValueError, "Gateway choice not found")

proc pickGatewayByLocation*(gw: string): Gateway {.gcsafe.} =
  let eipUrl = getEipUrl()
  let gws = getGateways(eipUrl)
  return manualGateway(gws, gw)

proc onDied(fd: AsyncFD): bool =
  debug("vpn died")
  releaseVpnLock()
  return true

proc canStartVpn(): bool =
  if int(getuid()) != 0:
    error("need to be run as root")
    return false
  return true

proc runVPNProc*(command: string): bool {.gcsafe.} =
  let canRun = vpnLock.tryAcquire()
  if not canRun:
    warn("cannot start vpn: locked")
    return false
  debug(command)
  try:
    let p = command.startProcess(options={poEvalCommand, poStdErrToStdOut})
    openvpnProc = p
    debug("openvpn pid: $#" % [$processID(p)])
    #XXX trouble with selectors, debug
    #addProcess(processID(p), onDied)
  except:
    echo "ERROR cannot launch openvpn"

proc getCert(certUrl, caUrl: string) {.async.} =
  dumpFile("/dev/shm/leap.crt", getURL(certUrl))

proc doInitVPN() =
  getCACrt()
  gw = getAutoGateway()
  # TODO we can fetch certs here already
  ledStatusOff()
  debug("Init done")

proc workerVPN*(proxy: ThreadProxy) {.thread.} =
  var mng: Manager
  var eipSt: EIPState
  var vpnSt: OpenVpnState
  var locations: seq[string]
  var selectedLocation: string
  var gws: seq[Gateway]
  var metrics: MetricsRef
  var timers: bool
  var count = 0
  var stopped: bool

  proc parseEipState(str: string) =
    let vpn = strToVPN(str)
    let eip = strToEIP(str)
    if vpn != vpnSt:
      vpnSt = vpn
      eipSt = eip
      echo "vpn: " & $vpnSt
    if eipSt == EIPState.ON:
      ledStatusOn()
    elif eipSt == EIPState.OFF:
      ledStatusOff()

  proc fetchStatus(fd: AsyncFD): bool {.gcsafe.} =
    if stopped:
      if $vpnSt != "OFF":
        echo "vpn: OFF"
      # XXX should check that no vpn is running, routes etc
      vpnSt = OpenVpnState.OFF
      eipSt = EIPState.OFF
      ledStatusOff()
      return
    try:
      if not mng.started:
        return
    except:
      warn("cannot add timer!!")
    try:
      let st = mng.getState.state
      parseEipState(st)
    except:
      if mng.terminated:
        if $vpnSt != "OFF":
          echo "vpn: OFF"
        vpnSt = OpenVpnState.OFF
        eipSt = EIPState.OFF
        ledStatusOff()

  proc collectMetrics(fd: AsyncFD): bool {.gcsafe.} =
    if eipSt != EIPState.ON:
      return
    callSoon(() => metrics.checkExitIP())
    callSoon(() => metrics.doPing())

  proc getManager(fd: AsyncFD): bool =
    while true:
      try:
        mng = connectToManagement()
        break
      except:
        echo getCurrentExceptionMsg()
        echo "ERROR cannot get manager!"
      sleep(500)

  proc doStart(fd: AsyncFD): bool {.gcsafe.} =
    if $vpnSt != "OFF":
      warn("WARN not starting, vpn status is " & $eipSt)
      return
    # in case locations have changed in the meantime
    stopped = false
    parseConfig()
    let prov = getProvider()
    # TODO check if we still have valid certs
    let certUrl = getCertUrl()
    let caUrl = getCaUrl()
    waitFor getCert(certUrl, caUrl)
    var gw: Gateway

    if selectedLocation != "":
      # parseConfig resets the location, we should write it to file
      setLocation(selectedLocation)

    if isAuto():
      gw = getAutoGateway()
      info("Using auto gateway: " & $gw.host)
    else:
      let loc = getLocation()
      debug("Current location: " & loc)
      gw = pickGatewayByLocation(loc)
      info("Using preferred location: " & $loc)
      info("Selected gateway: " & $gw.host)

    if useService():
      let cfg = getCommandFor(gw, oneline=false)
      dumpServiceConfig(prov, cfg)
      info("Using openvpn service")
      startService()
    else:
      let cmd = getCommandFor(gw)
      let ok = runVPNProc(cmd)

    addTimer(pollPeriod, true, getManager)
    addTimer(pollPeriod, false, fetchStatus)

    # TODO --- add metrics (in a separate thread?) ----------
    #metrics = MetricsRef()
    #addTimer(int(pollPeriod * 60), false, collectMetrics)
    # -------------------------------------------------------


  proc doStop(fd: AsyncFD): bool {.gcsafe.} =
    stopped = true

    # FIXME if connecting, should queue pending
    if $eipSt != "ON":
      echo "WARN not stopping, eip status is " & $eipSt
      return

    if useService():
      stopService()
    else:
      try:
        mng.doTerminate()
        sleepAsync(32).addCallback(()=>releaseVpnLock())
      except:
        echo getCurrentExceptionMsg()

  proc maybeStartVPN() =
    if isButtonON():
      debug("Switch is on, starting...")
      addTimer(500, true, doStart)

  proc doSetLocation(fd: AsyncFD): bool {.gcsafe.} =
    setLocation(selectedLocation)

  proxy.onData STATUS:
    return %* {STATUS: $eipSt}

  proxy.onData START:
    if not canStartVpn():
      return %* {START: "error"}
    addTimer(16, true, doStart)
    return %* {START: "ok"}

  proxy.onData STOP:
    addTimer(16, true, doStop)
    return %* {STOP: "ok"}

  proxy.onData GWLOCATIONS:
    return %* {GWLOCATIONS: $locations}

  proxy.onData GWLOCATIONSJSON:
    return  %* {GWLOCATIONSJSON: $(%* gws)}

  proxy.onData LOCATIONSET:
    let loc = data[0]
    selectedLocation = loc.getStr()
    addTimer(16, true, doSetLocation)
    return %* {LOCATIONSET: "ok"}

  mng = dummyManager()
  if not checkForManagement():
    error("ERROR (fatal) you need to install an openvpn variant with management interface enabled")
    quit()

  parseConfig()
  doBanner()
  checkForRoot()
  doInitBoard()
  doInitVPN()
  locations = listLocations()
  maybeStartVPN()
  gws = getGateways(getEipUrl())
  waitFor proxy.poll(interval=200)
  debug("Exiting event loop")
