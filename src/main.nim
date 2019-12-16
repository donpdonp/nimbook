# nim
import os, strformat, tables
# local
import config, nimbook, net, types

proc markets(config: config.Config) =
  var markets: seq[Market]

  for source in config.sources:
    try:
      var source_markets = net.marketlistload(source.market_list, source)
      markets.add(source_markets)
      echo &"{source.name} loaded {len(source_markets)} markets"
    except:
      let ex = getCurrentException()
      echo &"{source.name} : {ex.msg}"

  var matches:Table[(string, string), seq[Market]] = markets_match(markets)
  var matches_count = 0
  for k,v in matches.mpairs:
    if len(v) > 1:
      matches_count += 1
      echo &"{k} {v}"
  echo &"{matches_count} matching markets!"
  config.marketsave(matches)
  echo &"saved."

proc compare(config: Config, mpair: (string, string), matchingMarkets: var seq[Market]) =
  var askbooks = Books(askbid: AskBid.ask)
  var bidbooks = Books(askbid: AskBid.bid)
  for m in matchingMarkets.mitems:
    try:
      let (askoffers, bidoffers) = marketfetch(m, config)
      let askbook = Book(market: m, offers: askoffers)
      let bidbook = Book(market: m, offers: bidoffers)
      askbooks.books.add(askbook)
      bidbooks.books.add(bidbook)
      echo &"{m} asks {askbook} bids {bidbook}"
    except:
      let ex = getCurrentException()
      echo &"{m} : {ex.msg}"
  var (ask_wins, bid_wins) = overlap(mpair, askbooks, bidbooks)
  if ask_wins.books.len() > 0 or  bid_wins.books.len() > 0:
    echo &"**ASKWIN {mpair}: {ask_wins}"
    echo &"**BIDWIN {mpair}: {bid_wins}"
    trade(askbooks, bidbooks)
  echo ""

proc book(config: Config, base: string, quote: string) =
  var matches = config.marketload()
  echo &"loaded {len(matches)}"
  let mpair = (base, quote)
  var mmatches = matches[mpair]
  echo &"{mpair} {mmatches}"
  compare(config, mpair, mmatches)

proc bookall(config: Config) =
  var matches = config.marketload()
  echo &"loaded {len(matches)}"
  for k,v in matches.mpairs:
    if len(v) > 1:
      echo(&"{k} = {v}")
      compare(config, k, v)

proc help_closest(word: string) =
  echo word, "not understood"

proc help(config: Config) =
  echo "nimbook markets - find matching markets"
  echo "nimbook book <base> <quote> - compare orderbooks"
  echo "nimbook books - compare all orderbooks"

proc main(args: seq[string]) =
  echo "nimbook v0.1"
  var config = config.load("config.yaml")

  if len(args) > 0:
    case args[0]
      of "markets": markets(config)
      of "book": book(config, args[1], args[2])
      of "books": bookall(config)
      else: help(config) #help_closest(args[0])
  else:
    help(config)

proc ctrlc() {.noconv.} =
  quit("done")

setControlCHook(ctrlc)

## main
if isMainModule:
  try:
    main(os.commandLineParams())
  except:
    let ex = getCurrentException()
    echo &"isMainModule: {ex.name} : {ex.msg}"
    echo getStackTrace(ex)
