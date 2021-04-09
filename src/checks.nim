import strutils
import osproc
import posix

const
  managementSig = "management-exit"
  grepCmd = "grep $# /usr/sbin/openvpn" % [managementSig,]

proc checkForManagement*(): bool =
  let grep = execProcess(grepCmd)
  if "matches" in grep:
    return true
  return managementSig in grep

proc checkForRoot*() =
  if int(getuid()) != 0:
    echo "WARN not running as root. OpenVPN will not be able to start"
