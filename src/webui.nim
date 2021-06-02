import os

import prologue

import config
import curl

# Route handler

parseConfig()
let settings = newSettings()
var app = newApp(settings=settings)

proc getPath(file: string): string =
  if getEnv("DEBUGUI") == "":
    return "/www/bitmask/" & file
  else:
    return "../ui/" & file

app.addRoute("/main.js", proc(ctx: Context) {.async.} =
  await ctx.staticFileResponse(getPath("main.js"), "")
)

app.addRoute("/datamaps.world.min.js", proc(ctx: Context) {.async.} =
  await ctx.staticFileResponse(getPath("datamaps.world.min.js"), "")
)

app.addRoute("/", proc(ctx: Context) {.async.} =
  await ctx.staticFileResponse(getPath("index.html"), "")
)

app.addRoute("/cities.json", proc(ctx: Context) {.async.} =
  await ctx.staticFileResponse(getPath("cities.json"), "")
)

proc pong*(ctx: Context) {.async.} =
  resp "ok\n"

# -- debug ------------------------------------------
proc doLocations*(ctx: Context) {.async.} =
  resp $(%* getGateways(getEipUrl()))

app.get("/locations.json", doLocations)
app.get("/start", pong)
app.get("/status", pong)
app.get("/stop", pong)

# --------------------------------------------------
app.run()
