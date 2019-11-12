import os

include config
include nimbook

proc match(config: Config) =
  var markets: seq[Market]

  for source in config.sources:
    var source_markets = marketlistload(source.market_list, source.name)
    markets.add(source_markets)

  for market in markets:
    echo market.source, market

  var matches = markets_match(markets)

proc book(config: Config) =
  var matches: seq[MarketPair]
  echo "seq wut 1"
  for matched_pair in matches:
    echo "seq wut 2"
    var bid_book = marketload(config, matched_pair.a, Bid)
    var ask_book = marketload(config, matched_pair.b, Ask)
    var winners = overlap(bid_book, ask_book)

proc help_closest(word: string) =
  echo word, "not understood"

proc help(config: Config) =
  echo "nimbook match - find matching markets"
  echo "nimbook book - compare orderbooks"

proc main(args: seq[string]) =
  echo "nimbook v0.1"
  var config = load("config.yaml")

  if len(args) > 0:
    case args[0]
      of "match": match(config)
      of "book": book(config)
      else: help_closest(args[0])
  else:
    help(config)

## main
if isMainModule:
  try:
    main(os.commandLineParams())
  except:
    echo getCurrentExceptionMsg()
