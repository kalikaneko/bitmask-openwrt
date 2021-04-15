import locks
import random
import sugar

import threadproxy

import logs
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
  while i <= int(1E4):
    let d = respChan[].tryRecv()
    if d.dataAvailable:
      yield d.msg
    inc i
    waitFor sleepAsync(32)
    yield CmdRef(id:0, cmd: "")
  echo "out of getResponseIterator loop"

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
  waitFor sleepAsync(100)
  for resp in getResponseIterator():
    if resp.id == cmd.id:
      return resp.resp
    if resp.id != 0:
      # not ours, return to the queue
      callSoon(() => sendResponse(resp))

const
  MAIN = "main"
  WORKER = "worker_vpn"
  COUNT* = "count"
  START* = "start"
  STOP* = "stop"
  STATUS* = "status"
  GWLOCATIONS* = "gwlocations"

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

    proc processResponse(action: string, cmd: CmdRef) =
      try:
        let data = waitFor proxy.ask(WORKER, action)
        cmd.resp = data[action].getStr()
        callSoon(() => sendResponse(cmd))
      except:
         warn("BUG empty data when parsing command")
  
    # doParseCommands is a callback
    proc doParseCommands(fd: AsyncFD): bool {.gcsafe.} =
      let cmd = getCommandFromQueue()
      case cmd.cmd
      of "":
         return
      of COUNT:
        processResponse(COUNT, cmd)
      of START:
        processResponse(START, cmd)
      of STOP:
        processResponse(STOP, cmd)
      of STATUS:
        processResponse(STATUS, cmd)
      of GWLOCATIONS:
        processResponse(GWLOCATIONS, cmd)
      else:
        return
    addTimer(200, false, doParseCommands)
