import yaml/serialization, streams
import types

type
  JqBidAsk = object
    bids: string
    asks: string

  JqUrl = object
    url: string
    jq: string

  Source = object
    name : string
    url : string
    jq  : JqBidAsk
    market_list: JqUrl

type
  Config = object
    sources: seq[Source]


proc load(filename: string): Config =
  var config: Config
  var stream = newFileStream(filename)
  load(stream, config)
  stream.close()
  config

proc findSource(market: Market, config: Config): Source =
  for idx, source in config.sources:
    if source.name == market.source:
      return source
