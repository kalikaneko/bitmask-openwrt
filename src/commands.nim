import locks
import random
import sugar

import threadproxy

import vpn


randomize()

var hasWorker = false

type
  Cmd = object
   id: int
   cmd: string
   resp: string

  CmdRef* = ref Cmd

proc getChannel(): ptr Channel[CmdRef] =
  var channel = cast[ptr Channel[CmdRef]](
    allocShared0(sizeof(Channel[CmdRef]))
  )
  channel[].open(maxItems=0)
  return channel

var cmdChan = getChannel()
var respChan = getChannel()

proc createCommand(cmd: string): CmdRef =
  CmdRef(id:rand(10000), cmd: cmd)

proc getCommandFromQueue(): CmdRef =
  let d = cmdChan[].tryRecv()
  if d.dataAvailable:
    return d.msg
  CmdRef(id:0, cmd: "")

iterator getResponseIterator(): CmdRef =
  var i = 0
  while i <= 1000:
    let d = respChan[].tryRecv()
    if d.dataAvailable:
      yield d.msg
    inc i
    yield CmdRef(id:0, cmd: "")

template retryUntilSent(cmd:CmdRef, chan: Channel) =
  while true:
    let ok = chan.trySend(cmd)
    if ok:
      break

proc sendResponse(cmd: CmdRef) =
  retryUntilSent(cmd, respChan[])

proc getResponse*(cmdStr: string): Future[string] {.async.} =
  let cmd = createCommand(cmdStr)
  retryUntilSent(cmd, cmdChan[])
  for resp in getResponseIterator():
    if resp.id == cmd.id:
      return resp.resp
    if resp.id != 0:
      # not ours, return to the queue
      callSoon(() => sendResponse(resp))
    await sleepAsync(100)

const
  MAIN = "main"
  WORKER = "worker_vpn"
  COUNT* = "count"
  START* = "start"
  STOP* = "stop"
  STATUS* = "status"
  GWLOCATIONS* = "gwlocations"

# proxy is in scope where this template is used below
template processResponse(action: string) =
  let data = waitFor proxy.ask(WORKER, action)
  cmd.resp = data[action].getStr()
  callSoon(() => sendResponse(cmd))

var workerLock*: Lock
initLock(workerLock)

proc registerCommandDispatcher*() =
  withLock workerLock:
    if hasWorker:
      return
    var proxy = newMainThreadProxy(MAIN)

    asyncCheck proxy.poll()
    proxy.createThread(WORKER, workerVPN)
    hasWorker = true
    echo "DEBUG Init vpn worker"

    # signature for a Callback is this weird
    proc doParseCommands(fd: AsyncFD): bool {.gcsafe.} =
      let cmd = getCommandFromQueue()
      case cmd.cmd
      of COUNT:
        processResponse(COUNT)
      of START:
        processResponse(START)
      of STOP:
        processResponse(STOP)
      of STATUS:
        processResponse(STATUS)
      of GWLOCATIONS:
        processResponse(GWLOCATIONS)
      else:
        return
    # here we register an ad-hoc event loop that will be called by a timer
    # right before starting the webserver event loop.
    addTimer(200, false, doParseCommands)
