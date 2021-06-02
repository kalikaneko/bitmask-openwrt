import os
import osproc
import posix
import prologue
import strutils

import commands
import logs
import webapi

var localIp = "localhost"
if getEnv("WEBUI_INSECURE") == "1":
  localIp = execProcess("uci get network.lan.ipaddr")
  localIp = localIp.strip()
  echo "INFO: Listening on " & localIp

let
  initialize = initEvent(registerCommandDispatcher)
  settings = newSettings(
    appName = "bitmask",
    address=localIp,
    debug=false)

proc getPath(file: string): string =
  if getEnv("DEBUGUI") == "":
    return "/www/bitmask/" & file
  else:
    return "../ui/" & file

when isMainModule:
  onSignal(posix.SIGTERM):
    info("SIGTERM Received")
    #doStop
    quit()

  var app = newApp(settings = settings, startup = @[initialize])
  app.get("/status", doStatus)
  app.get("/getip", doGetIp)
  app.get("/start", doStart)
  app.get("/stop", doStop)
  app.get("/locations", doLocations)
  app.get("/locations/set/{location}", doSetLocation)
  app.get("/locations/auto}", doSetAutoLocation)
  app.get("/locations.json", doLocationsJson)
  app.get("/main.js", proc(ctx: Context) {.async.} =
    await ctx.staticFileResponse(getPath("main.js"), ""))
  app.get("/d3.min.js", proc(ctx: Context) {.async.} =
    await ctx.staticFileResponse(getPath("d3.min.js"), ""))
  app.get("/mini.css", proc(ctx: Context) {.async.} =
    await ctx.staticFileResponse(getPath("mini.css"), ""))
  app.get("/topojson.min.js", proc(ctx: Context) {.async.} =
    await ctx.staticFileResponse(getPath("topojson.min.js"), ""))
  app.get("/datamaps.world.min.js", proc(ctx: Context) {.async.} =
    await ctx.staticFileResponse(getPath("datamaps.world.min.js"), ""))
  app.get("/cities.json", proc(ctx: Context) {.async.} =
    await ctx.staticFileResponse(getPath("cities.json"), ""))
  app.get("/img/riseup.png", proc(ctx: Context) {.async.} =
    await ctx.staticFileResponse(getPath("riseup.png"), ""))
  app.get("/", proc(ctx: Context) {.async.} =
    await ctx.staticFileResponse(getPath("index.html"), ""))
  app.run()
