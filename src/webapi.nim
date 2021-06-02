import strutils
import sugar
import prologue

import commands
import config
import curl

proc doStatus*(ctx: Context) {.async,gcsafe.} =
  let response = waitFor getResponse(STATUS)
  resp response & "\n"

proc doGetIp*(ctx: Context) {.async,gcsafe.} =
  var str = getExternalURL(wtfIpUrl)
  str = str.replace("\n")
  str = str.replace(" ")
  resp str & "\n"

proc doStart*(ctx: Context) {.async,gcsafe.} =
  let response = waitFor getResponse(START)
  resp response & "\n"

proc doStop*(ctx: Context) {.async,gcsafe.} =
  let response = waitFor getResponse(STOP)
  resp response & "\n"

proc doLocations*(ctx: Context) {.async,gcsafe.} =
  let response = waitFor getResponse(GWLOCATIONS)
  resp response & "\n"

proc doLocationsJson*(ctx: Context) {.async,gcsafe.} =
  let response = waitFor getResponse(GWLOCATIONSJSON)
  resp response & "\n"

# no need to go through the worker proxy, or??? aah, GC-safe...

proc doSetLocation*(ctx: Context) {.async,gcsafe.} =
  let loc = ctx.getPathParams("location", "")
  let response = waitFor getResponseWithArg(LOCATIONSET, loc)
  resp response & "\n"

proc doSetAutoLocation*(ctx: Context) {.async,gcsafe.} =
  callSoon(() => setAuto(true))
  resp "ok\n"

