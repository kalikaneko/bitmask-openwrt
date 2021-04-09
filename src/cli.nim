#when isMainModule:
#  debug("bitmask up and running")
#  var p = newParser("bitmask-vpn"):
#    flag("-v", "--verbose",  help="Get more output")
#    option("-gw", "--gateway", help="Preferred gateway")
#    option("-p", "--port", help="Port for web api")
#    command("start-server"):
#      help("Start web server, run in the background")
#    run:
#        echo("should start in the background")
#        doRunServer()
#        #daemonize("/tmp/bitmask.pid", "/dev/null", "/tmp/bitmask.out", "/tmp/bitmask.err", "/"):
#    command("check"):
#      help("Check connectivity to a gateway")
#      run:
#        var gw = opts.parentOpts.gateway
#        setVerbose(opts.parentOpts.verbose)
#    command("connect"):
#      help("Establish a VPN tunnel to a gateway")
#      run:
#        setVerbose(true)
#        var gw = opts.parentOpts.gateway
#    command("list"):
#      help("List available gateways")
#      run:
#        waitFor listGateways()
#  p.run(os.commandLineParams())

#proc promptSelectGateway(gateways: seq[Gateway]): Gateway =
#    fgBlue.styledEcho styleBright, "[bitmask] Please select a gateway:"
#    for i in 0 .. len(gateways)-1:
#      echo " ", i, ": ", gateways[i].location
#    echo "?:>"
#    let chosen = parseInt(readLine(stdin))
#    result = gateways[chosen]

