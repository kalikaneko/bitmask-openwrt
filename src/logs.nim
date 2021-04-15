import os


template debug*(msg: string)=
  if getEnv("DEBUG") != "":
    echo "DEBUG " & msg

template warn*(msg: string)=
  echo "WARN " & msg

template info*(msg: string)=
  echo "INFO " & msg

template error*(msg: string)=
  echo "ERROR " & msg

template bug*(msg: string)=
  echo "BUG " & msg
