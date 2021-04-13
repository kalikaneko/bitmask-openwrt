#!/usr/bin/env nim
mode = ScriptMode.Verbose
let appName = "bitmaskd"
if existsFile appName & ".exe": rmFile appName & ".exe"
if existsFile appName:
    rmFile appName
exec """nim compile --d:release --threads:on --opt:size --passl:-s --cpu:ia64 -t:-m64 -l:-m64 --stackTrace:on --lineTrace:on --out:"bitmaskd" bitmask.nim"""
#--d:release
# --gc:arc
# -d:usestd
