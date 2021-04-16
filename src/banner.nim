import config

const riseup: string = r"""

================================================
 ____  _                   __     ______  _   _
|  _ \(_)___  ___ _   _ _ _\ \   / |  _ \| \ | |
| |_) | / __|/ _ | | | | '_ \ \ / /| |_) |  \| |
|  _ <| \__ |  __| |_| | |_) \ V / |  __/| |\  |
|_| \_|_|___/\___|\__,_| .__/ \_/  |_|   |_| \_|
                       |_|

                 _.----._
               ,'.::.--..:._
              /::/_,-< )::;_`-._
             ::::::::`-';'`,--`-`
             ;::;'|::::,','
           ,'::/  ;:::/, :.
          /,':/  /::;' \ ':\
         :'.:: ,-''   . `.::\
         \.:;':.    `    :: .:
         (;' ;;;       .::' :|
          \,:;;      \ `::.\.\
          `);'        '::'  `:
           \.  `        `'  .:      _,'
            `.: ..  -. ' :. :/  _.-' _.-
              >;._.:._.;,-=_(.-'  __ `._
            ,;'  _..-((((''  .,-''  `-._
         _,'<.-''  _..``'.'`-'`.        `
     _.-((((_..--''       \ \ `.`.
   -'  _.``'               \      ` 
     ,'

The RiseupVPN service is entirely funded through
donations from users. If you value an easy,
non-profit VPN service that does not track users,
then please contribute to keeping RiseupVPN
alive.
                   https://riseup.net/vpn/donate

================================================

"""
proc doBanner*()=
  if getProvider() == "riseup":
    echo riseup
