import strutils
import prologue
import commands

proc doStatus*(ctx: Context) {.async,gcsafe.} =
  let response = waitFor getResponse(STATUS)
  resp response & "\n"

proc doStart*(ctx: Context) {.async,gcsafe.} =
  let response = waitFor getResponse(START)
  resp response & "\n"

proc doStop*(ctx: Context) {.async,gcsafe.} =
  let response = waitFor getResponse(STOP)
  resp response & "\n"

proc doLocations*(ctx: Context) {.async,gcsafe.} =
  let response = waitFor getResponse(GWLOCATIONS)
  resp response & "\n"

proc doCount*(ctx: Context) {.async,gcsafe.} =
  let response = waitFor getResponse(COUNT)
  resp response & "\n"
