# nim
import os, strformat
# local
include config
include nimbook

proc markets(config: Config) =
  var markets: seq[Market]

  for source in config.sources:
    try:
      var source_markets = marketlistload(source.market_list, source.name)
      markets.add(source_markets)
      echo &"{source.name} loaded {len(source_markets)} markets"
    except:
      let ex = getCurrentException()
      echo &"{source.name} : {ex.msg}"

  var matches = markets_match(markets)
  var matches_count = 0
  for k,v in matches.mpairs:
    if len(v) > 1:
      matches_count += 1
  echo &"{matches_count} matching markets!"

# proc book(config: Config) =
#   var matches: seq[MarketPair]
  for k,v in matches.mpairs:
    if len(v) > 1:
      echo(&"{k} = {v}")
      for m in v.mitems:
        try:
          echo m.source_name
          marketload(m, config)
          echo &"{m.source_name}:{m.base}/{m.quote} {len(m.bqbook)} asks {len(m.qbbook)} bids"
        except:
          let ex = getCurrentException()
          echo &"{m.source_name}:{m.base}/{m.quote} : {ex.msg}"
      var (best_ask, best_bid) = bestes(v)
      var ask_winners = overlap(k, v, best_bid, AskBid.ask)
      if len(ask_winners) > 0:
        echo &"!ASKWIN {k}: <{best_bid} {ask_winners}"
      var bid_winners = overlap(k, v, best_ask, AskBid.bid)
      if len(bid_winners) > 0:
        echo &"!BIDWIN {k}: >{best_ask} {bid_winners}"

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
