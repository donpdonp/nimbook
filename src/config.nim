import yaml/serialization, streams
import types

type
  JqBidAsk = object
    bids: string
    asks: string

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
