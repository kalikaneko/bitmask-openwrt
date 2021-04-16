import posix
import prologue

import commands
import logs
import webapi

let
  initialize = initEvent(registerCommandDispatcher)
  settings = newSettings(
    appName = "bitmask", address="localhost", debug=false)

when isMainModule:
  onSignal(posix.SIGTERM):
    info("SIGTERM Received")
    #doStop
    quit()

  var app = newApp(settings = settings, startup = @[initialize])
  app.addRoute("/status", doStatus)
  app.addRoute("/start", doStart)
  app.addRoute("/stop", doStop)
  app.addRoute("/count", doCount)
  app.addRoute("/locations", doLocations)
  app.run()
