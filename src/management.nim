## Bitmask telnet helper library
## Copyright Kali Kaneko <kali@leap.se>
## Released under GPLv3 License, see LICENSE file

import net
import strutils
import os

import logs

export Port

type
  Version* = ref object of RootObj
    openvpn: int
    management: int
  Manager* = ref object of RootObj
    sock: Socket
    version: Version
    started*: bool
    terminated*: bool

proc stripLineEnd(s: var string) =
  ## copied from strutils in nim 0.20
  if s.len > 0:
    case s[^1]
    of '\n':
      if s.len > 1 and s[^2] == '\r':
        s.setLen s.len-2
      else:
        s.setLen s.len-1
    of '\r', '\v', '\f':
      s.setLen s.len-1
    else:
      discard

proc readLine(s: Socket): string =
  result = ""
  while true:
    try:
      let r = s.recv( size=1, timeout=500)
      if r == "":
        # socket is closed
        return
      result.add r
      if r == "\n":
        result.stripLineEnd
        return
    except:
      return

proc dummyManager*(): Manager =
  new result
  var s = newSocket()
  result.sock = s
  result.terminated = false

proc connectToManagement*(ipaddr="127.0.0.1", port=6061.Port): Manager =
  new result
  var s = newSocket()
  result.sock = s
  result.terminated = false
  s.connect(ipaddr, port)
  result.started = true

proc send*(m: Manager; data: string): bool =
  return m.sock.trySend(data & "\n")

proc readLine*(m: Manager): string =
  m.sock.readLine()

proc parseCmdResponse(s: Manager): string =
  result = ""
  while true:
    let v = s.readLine
    if v == "":
      break
    if v == "END":
      result.stripLineEnd
      break
    result.add v & "\n"

proc getVersion*(m: Manager): string =
  if m.send("version"):
    return m.parseCmdResponse
  else:
    return ""

proc parseState(str: string): tuple {.raises: [ValueError] .} =
  let s = str.split(',')
  if s.len == 9:
    var state = (ts:  s[0], state: s[1], verb:  s[2], ltun:  s[3],
                 rem: s[4], rport: s[5], laddr: s[6], lport: s[7], ip6: s[8])
    return state
  elif (s.len == 8):
    var state = (ts: s[0], state: s[1], verb:  "", ltun:  "",
                 rem:"",   rport: "",   laddr: "", lport: "", ip6: "")
    return state
  else:
    #debug("State length: " & $str.len)
    raise newException(ValueError, "cannot parse state")

proc getState*(m: Manager): tuple =
  if m.send("state"):
    let r = m.parseCmdResponse
    parseState(r)
  else:
    parseState("")

proc doTerminate*(m: Manager): void =
  m.terminated = true
  m.started = false
  m.sock.send("signal SIGTERM\n")
  m.sock.close()

when isMainModule:
  let s = connectToManagement()
  discard s.getVersion
  echo "INFO " & $s.getState
