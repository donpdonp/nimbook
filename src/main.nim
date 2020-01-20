# nim
import os, strformat, tables, times
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

  var matches:Table[(string, string), seq[Market]] = marketpairs_group(markets)
  var matches_count = 0
  for k,v in matches.mpairs:
    if len(v) > 1:
      matches_count += 1
      echo &"{k} {v}"
  echo &"{matches_count} matching markets!"
  config.marketsave(matches)
  echo &"saved."

proc compare(config: Config, ticker_pair: (Ticker, Ticker), matchingMarkets: var seq[Market]) =
  let arb_id = arb_id_gen()
  var (askbooks, bidbooks) = marketsload(arb_id, ticker_pair, matchingMarkets)
  var (best_ask_market, best_ask) = bestprice(askbooks)
  var (best_bid_market, best_bid) = bestprice(bidbooks)
  if best_ask_market != nil and best_bid_market != nil:
    echo &"{ticker_pair} best_ask {best_ask_market} {best_ask.quote:0.5f} | {best_bid.quote:0.5f} {best_bid_market} best_bid"
    let quote_ticker = ticker_pair[1]
    let ask_price_wins = askbooks.offers_better_than(best_bid.quote, quote_ticker)
    let bid_price_wins = bidbooks.offers_better_than(best_ask.quote, quote_ticker)
    if ask_price_wins.books.len() > 0 or  bid_price_wins.books.len() > 0:
      echo &"*ASKWIN {ticker_pair}: {ask_price_wins}"
      echo &"*BIDWIN {ticker_pair}: {bid_price_wins}"
      #bookssave(ask_price_wins, "ask_wins")
      #bookssave(bid_price_wins, "bid_wins")
      let total_op = min(ask_price_wins.base_total(), bid_price_wins.base_total())
      let (ask_orders, bid_orders, profit) = trade(ask_price_wins, bid_price_wins)
      echo &"*ORDER {ask_orders}"
      echo &"*ORDER {bid_orders}"
      let cost = ask_orders.base_total
      arbpub(config, ticker_pair, ask_price_wins, best_ask.quote, bid_price_wins, best_bid.quote, cost, profit)
      echo &"*Cost {cost:0.5f} Profit {profit:0.5f} {ticker_pair[1]} ratio {(profit/cost):0.5f} {arb_id} {now()}"
  else:
    echo "totally empty."
  echo ""

proc book(config: Config, base: string, quote: string) =
  var matches = config.marketload()
  let market_pair = (Ticker(symbol:base), Ticker(symbol:quote))
  var market_matches = matches[(market_pair[0].symbol, market_pair[1].symbol)]
  echo &"{market_pair} {market_matches}"
  var market_equals = marketpairs_equal(market_matches)
  compare(config, market_pair, market_equals)

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
  let config_file = "config.yaml"
  var config = config.load(config_file)
  echo "nimbook v0.2 ({config_file} loaded)"
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
