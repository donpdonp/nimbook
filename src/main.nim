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

  var matches:Table[(string, string), seq[Market]] = marketpairs_match(markets)
  var matches_count = 0
  for k,v in matches.mpairs:
    if len(v) > 1:
      matches_count += 1
      echo &"{k} {v}"
  echo &"{matches_count} matching markets!"
  config.marketsave(matches)
  echo &"saved."

proc compare(config: Config, ticker_pair: (Ticker, Ticker), matchingMarkets: var seq[Market]) =
  var askbooks = Books(askbid: AskBid.ask)
  var bidbooks = Books(askbid: AskBid.bid)
  for market in matchingMarkets.mitems:
    try:
      var (askoffers, bidoffers) = marketfetch(market)
      echo &"swap check {ticker_pair} vs {market.base}/{market.quote} = {market.ticker_pair_swapped(ticker_pair)}"
      if market.ticker_pair_swapped(ticker_pair):
        (askoffers, bidoffers) = swapsides(askoffers, bidoffers)
        let market_temp = market.base
        market.base = market.quote
        market.quote = market_temp
      let askbook = Book(market: market, offers: askoffers)
      let bidbook = Book(market: market, offers: bidoffers)
      askbooks.books.add(askbook)
      bidbooks.books.add(bidbook)
      echo &"{market} asks {askbook} bids {bidbook}"
    except:
      let ex = getCurrentException()
      echo &"{market} : {ex.msg}"
  var (ask_wins, bid_wins) = overlap(ticker_pair, askbooks, bidbooks)
  if ask_wins.books.len() > 0 or  bid_wins.books.len() > 0:
    echo &"**ASKWIN {ticker_pair}: {ask_wins}"
    echo &"**BIDWIN {ticker_pair}: {bid_wins}"
    trade(askbooks, bidbooks)
  echo ""

proc book(config: Config, base: string, quote: string) =
  var matches = config.marketload()
  echo &"loaded {len(matches)}"
  let mpair = (Ticker(symbol:base), Ticker(symbol:quote))
  var mmatches = matches[(mpair[0].symbol, mpair[1].symbol)]
  echo &"{mpair} {mmatches}"
  compare(config, mpair, mmatches)

proc bookall(config: Config) =
  var matches = config.marketload()
  echo &"loaded {len(matches)}"
  for k,v in matches.mpairs:
    if len(v) > 1:
      echo(&"{k} = {v}")
      compare(config, (Ticker(symbol:k[0]), Ticker(symbol:k[1])), v)

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
