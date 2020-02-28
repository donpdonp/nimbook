# nim
import os, strformat, tables, times, options
# local
import config, nimbook, net, types

proc markets(config: config.Config) =
  var markets: seq[Market]

  for source in config.activeSources:
    try:
      var source_markets = net.marketlistload(source)
      markets.add(source_markets)
      echo &"{source.name} loaded {len(source_markets)} markets"
    except:
      let ex = getCurrentException()
      echo &"{source.name} : {ex.msg}"

  var matches: Table[(string, string), seq[Market]] = nimbook.marketpairs_group(markets)
  var matches_count = 0
  for k, v in matches.mpairs:
    if len(v) > 1:
      matches_count += 1
      echo &"{k} {v}"
  echo &"{matches_count} matching markets!"
  config.marketsave(matches)
  echo &"saved."

proc compare(config: Config, arb_id: string, market_pair: (Ticker, Ticker),
    matchingMarkets: var seq[Market]): Option[ArbReport] =
  var (askbooks, bidbooks) = marketsload(arb_id, market_pair, matchingMarkets)
  var (best_ask_market, best_ask) = bestprice(askbooks)
  var (best_bid_market, best_bid) = bestprice(bidbooks)
  if best_ask_market != nil and best_bid_market != nil:
    echo &"{market_pair[0]}/{market_pair[1]} best_ask {best_ask_market} {best_ask.quote:0.5f} | {best_bid.quote:0.5f} {best_bid_market} best_bid"
    let quote_ticker = market_pair[1]
    let ask_price_wins = askbooks.offers_better_than(best_bid.quote, quote_ticker)
    let bid_price_wins = bidbooks.offers_better_than(best_ask.quote, quote_ticker)
    if ask_price_wins.books.len() > 0 or bid_price_wins.books.len() > 0:
      echo &"*ASKWIN {market_pair}: {ask_price_wins}"
      echo &"*BIDWIN {market_pair}: {bid_price_wins}"
      #bookssave(ask_price_wins, "ask_wins")
      #bookssave(bid_price_wins, "bid_wins")
      let total_op = min(ask_price_wins.base_total(), bid_price_wins.base_total())
      let (ask_orders, bid_orders, profit) = trade(ask_price_wins, bid_price_wins)
      echo &"*ORDER {ask_orders}"
      echo &"*ORDER {bid_orders}"
      let avg_price = best_ask.quote + (best_bid.quote - best_ask.quote)/2
      let cost = ask_orders.cost
      let ratio = profit / cost
      let report = ArbReport(id: arb_id, pair: (market_pair[0].symbol,market_pair[1].symbol), 
        ask_books: ask_orders, bid_books: bid_orders, cost: cost, profit: profit,
        avg_price: avg_price, ratio: ratio)
      return some(report)
  else:
    echo "totally empty."
    return none[ArbReport]()

proc book(config: Config, matches: MarketMatches, base: Ticker, quote: Ticker) =  
  let usd = Ticker(symbol:"USD")
  let arb_id = arb_id_gen()
  let market_pair = (base, quote)
  var market_matches = matches[(market_pair[0].symbol, market_pair[1].symbol)]
  echo &"={market_pair[0]}/{market_pair[1]} {market_matches}"
  #var market_equals = marketpairs_equal(market_matches) #future constraint
  let arb_opt = compare(config, arb_id, market_pair, market_matches)
  if arb_opt.isSome:
    var arb = arb_opt.get
    let profit_usd = nimbook.currency_convert(arb.profit, quote, usd)
    arb.profit_usd = profit_usd
    if profit_usd > config.settings.profit_minimum:
      arbPush(config, arb)
    echo &"*Cost {arb.ask_books.base_total:0.5f}{arb.pair[0]}/{arb.cost:0.5f}{arb.pair[1]} profit {arb.profit:0.5f}{arb.pair[1]} profit_usd: {arb.profit_usd:0.5f} {arb.ratio:0.3f}x {arb.id} {now().`$`}"

proc bookall(config: Config, matches: MarketMatches) =
  var matches = config.marketload()
  echo &"loaded {len(matches)}"
  for k, v in matches.pairs:
    if len(v) > 1:
      book(config, matches, Ticker(symbol:k[0]), Ticker(symbol:k[1]))
      if config.settings.delay > 0:
        echo ""
        sleep(int(config.settings.delay*1000))

proc help_closest(word: string) =
  echo word, "not understood"

proc help(config: Config) =
  echo "nimbook markets - find matching markets"
  echo "nimbook book <base> <quote> - compare orderbooks"
  echo "nimbook books - compare all orderbooks"

proc main(args: seq[string]) =
  let config_file = "config.yaml"
  var config = config.load(config_file)
  echo &"nimbook v0.2 ({config_file} loaded)"
  if len(args) > 0:
    case args[0]
      of "markets": markets(config)
      of "book": book(config, config.marketload(), Ticker(symbol:args[1]), Ticker(symbol:args[2]))
      of "books": bookall(config, config.marketload())
      else: help(config) #help_closest(args[0])
  else:
    help(config)

proc ctrlc() {.noconv.} =
  quit("ctrl-c")

setControlCHook(ctrlc)

## main
if isMainModule:
  try:
    main(os.commandLineParams())
  except:
    let ex = getCurrentException()
    echo &"isMainModule: {ex.name} : {ex.msg}"
    echo getStackTrace(ex)
