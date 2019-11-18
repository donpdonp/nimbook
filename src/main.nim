# nim
import os, strformat
# local
include config
include nimbook

proc markets(config: Config) =
  var markets: seq[Market]

  for source in config.sources:
    var source_markets = marketlistload(source.market_list, source.name)
    markets.add(source_markets)

  for market in markets:
    echo market.source, market

  var matches = markets_match(markets)

# proc book(config: Config) =
#   var matches: seq[MarketPair]
  for k,v in matches.mpairs:
    if len(v) > 1:
      echo(&"{k} = {v}")
      for m in v.mitems:
        echo m.source
        marketload(m, config)
    # var bid_book = marketload(config, matched_pair.a, Bid)
    # var ask_book = marketload(config, matched_pair.b, Ask)
    # var winners = overlap(bid_book, ask_book)

proc help_closest(word: string) =
  echo word, "not understood"

proc help(config: Config) =
  echo "nimbook markets - find matching markets"
  echo "nimbook book - compare orderbooks"

proc main(args: seq[string]) =
  echo "nimbook v0.1"
  var config = load("config.yaml")

  if len(args) > 0:
    case args[0]
      of "markets": markets(config)
      #of "book": book(config)
      else: markets(config) #help_closest(args[0])
  else:
    help(config)

## main
if isMainModule:
  try:
    main(os.commandLineParams())
  except:
    let ex = getCurrentException()
    echo &"isMainModule: {ex.name} : {ex.msg}"
    echo getStackTrace(ex)
