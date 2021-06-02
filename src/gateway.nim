type
  Transport = object
    `type`*: string
    protocols*: seq[string]
    ports*: seq[string]

  Capabilities = object
    adblock: bool
    filter_dns: bool
    limited: bool
    user_ips: bool
    transport*: seq[Transport]

  Gateway* = object
    location*: string
    ip_address*: string
    host*: string
    capabilities*: Capabilities
    cc*: string
    hemisphere*: string
    locationName*: string

  GatewayV1 * = object
    ip_address*: string
    host*: string

  Location* = object
    country_code*: string
    hemisphere*: string
    name*: string
    timezone*: string
