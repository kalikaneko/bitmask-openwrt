import streams

proc dumpFile*(pth: string, data: string) =
  let s = newFileStream(pth, fmWrite)
  s.write(data)
  s.close()

