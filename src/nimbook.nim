# nim
import strformat, strutils, tables, sequtils, options, times, os
# nimble
# local
import types, net, config, eth, quant

proc bestprice*(books: Books): (Market, Offer) =
  let best_side_price: float = if books.askbid == AskBid.ask: high(float) else: 0
  var best_offer = Offer(base_qty: 0, quote: best_side_price)
  var best_market: Market
  for b in books.books:
    if len(b.offers) > 0:
      let book_best = b.best
      if books.askbid == AskBid.ask:
        if book_best.quote < best_offer.quote:
          best_offer = book_best
          best_market = b.market
      else:
        if book_best.quote > best_offer.quote:
          best_offer = book_best
          best_market = b.market
  (best_market, best_offer)

proc marketfetch*(arb_id: string, market: var Market): (seq[Offer], seq[Offer]) =
  var url = market.source.url.replace("%base%", market.base.symbol).replace(
      "%quote%", market.quote.symbol)
  echo url
  let offers_json: string = net.getContent(url)
  config.jsonsave(arb_id, market.`$`, offers_json)

  var (asks, bids) = marketoffers_format(offers_json, market)
  if len(asks) > 0:
    let best_ask = asks[low(asks)]
    let worst_ask = asks[high(asks)]
    if best_ask.quote > worst_ask.quote:
      echo &"{market.source.name}, Warning, asks are reverse-order {best_ask.quote} > {worst_ask.quote}"
  if len(bids) > 0:
    let best_bid = bids[low(bids)]
    let worst_bid = bids[high(bids)]
    if best_bid.quote < worst_bid.quote:
      echo &"{market.source.name},  Warning, bids are reverse-order {best_bid.quote} < {worst_bid.quote}"
  (asks, bids)

proc marketpairs_group*(markets: seq[Market]): Table[(string, string), seq[Market]] =
  var winners: Table[(string, string), seq[Market]]
  for market in markets:
    let grouping_pair = market.grouping_pair()
    if grouping_pair[1] == "eth": ## todo take off eth-only hack
      if not winners.hasKey(grouping_pair):
        winners[grouping_pair] = @[market]
      else:
        winners[grouping_pair].add(market)
  winners

proc marketpairs_equal*(markets: seq[Market]): seq[Market] =
  var winners: seq[Market]
  for m1 in markets:
    for m2 in markets:
      if m1.base_contract == m2.base_contract:
        let x = 1
  markets

proc swapsides*(asks: seq[Offer], bids: seq[Offer]): (seq[Offer], seq[Offer]) =
  var swapped_asks = bids.map(proc (o: Offer): Offer = o.swap())
  var swapped_bids = asks.map(proc (o: Offer): Offer = o.swap())
  (swapped_asks, swapped_bids)

proc marketsload*(arb_id: string, ticker_pair: (Ticker, Ticker),
    matchingMarkets: var seq[Market]): (Books, Books) =
  var askbooks = Books(askbid: AskBid.ask)
  var bidbooks = Books(askbid: AskBid.bid)
  for market in matchingMarkets.mitems:
    try:
      var (askoffers, bidoffers) = marketfetch(arb_id, market)
      if market.ticker_pair_swapped(ticker_pair):
        (askoffers, bidoffers) = swapsides(askoffers, bidoffers)
        let market_temp = market.base
        market.base = market.quote
        market.quote = market_temp
        market.swapped = true
      let askbook = Book(market: market, offers: askoffers)
      if askoffers.len > 0:
        askbooks.books.add(askbook)
      let bidbook = Book(market: market, offers: bidoffers)
      if bidoffers.len > 0:
        bidbooks.books.add(bidbook)
      echo &" asks {askbook}"
      echo &" bids {bidbook}"
    except:
      let ex = getCurrentException()
      echo &"IOERR {market} : {ex.msg}"
  (askbooks, bidbooks)

proc currency_convert*(from_ticker: Ticker, to_ticker: Ticker): float =
  if to_ticker.symbol == "usd" or to_ticker.symbol == "USD":
    if from_ticker.symbol == "usd" or from_ticker.symbol == "USD":
      1.0
    else:
      let ratio_usd = net.coincap(from_ticker)
      echo &"coincap: {from_ticker} {ratio_usd:0.2f}USD"
      ratio_usd
  else:
    1.0

proc markets*(config: config.Config) =
  var markets: seq[Market]

  for source in config.activeSources:
    try:
      var source_markets = net.marketlistload(source)
      markets.add(source_markets)
      echo &"{source.name} loaded {len(source_markets)} markets"
    except:
      let ex = getCurrentException()
      echo &"{source.name} : {ex.msg}"

  var matches: Table[(string, string), seq[Market]] = marketpairs_group(markets)
  var matches_count = 0
  for k, v in matches.mpairs:
    if len(v) > 1:
      matches_count += 1
      echo &"{k} {v}"
  echo &"{matches_count} matching markets!"
  config.marketsave(matches)
  echo &"saved."

proc compare(config: Config, arb_id: string, market_pair: (Ticker, Ticker),
    matchingMarkets: var seq[Market], gas_price: int): Option[ArbReport] =
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
      let (ask_orders, bid_orders, trade_profit) = quant.trade(ask_price_wins, bid_price_wins)
      let fee_eth = quant.fee_eth(ask_orders, bid_orders, gas_price)
      echo &"*ORDER {ask_orders}"
      echo &"*ORDER {bid_orders}"
      let cost = ask_orders.cost
      let profit = trade_profit - fee_eth # todo only works on eth quote token
      let ratio = profit / cost
      let report = ArbReport(id: arb_id,
        date: now().format("yyyy-MM-dd'T'HH:mm:ss"),
        pair: (market_pair[0].symbol,
               market_pair[1].symbol),
        ask_books: ask_orders,
        bid_books: bid_orders,
        cost: cost,
        profit: profit,
        fee_eth: fee_eth,
        ratio: ratio)
      return some(report)
  else:
    echo "totally empty."
    return none[ArbReport]()

proc book*(config: Config, matches: MarketMatches, base: Ticker,
    quote: Ticker, gas_price: int64) =
  let usd_ticker = Ticker(symbol: "USD")
  let arb_id = arb_id_gen()
  let market_pair = (base, quote)
  var market_matches = matches[(market_pair[0].symbol, market_pair[1].symbol)]
  echo &"={market_pair[0]}/{market_pair[1]} {market_matches}"
  #var market_equals = marketpairs_equal(market_matches) #future constraint
  let arb_opt = compare(config, arb_id, market_pair, market_matches, 0)
  if arb_opt.isSome:
    var arb = arb_opt.get
    let usd_ratio = currency_convert(quote, usd_ticker)
    arb.profit_usd = arb.profit * usd_ratio
    if arb.profit_usd > config.settings.profit_minimum and
       arb.ratio > config.settings.ratio_minimum:
      arbPush(config, arb)
    echo &"*Cost {arb.ask_books.base_total:0.5f}{arb.pair[0]}/{arb.cost:0.5f}{arb.pair[1]}" &
    &" fee_eth {arb.fee_eth:0.5f}" &
    &" profit {arb.profit:0.5f}{arb.pair[1]} profit_usd: {arb.profit_usd:0.5f} {arb.ratio:0.3f}x" &
    &" {arb.id} {now().`$`}"

proc bookall*(config: Config, matches: MarketMatches) =
  var matches = config.marketload()
  echo &"loaded {len(matches)} markets"
  var gas_fast_wei = eth.gas_wei()
  for k, v in matches.pairs:
    if len(v) > 1:
      book(config, matches, Ticker(symbol: k[0]), Ticker(symbol: k[1]), gas_fast_wei)
      if config.settings.delay > 0:
        echo ""
        sleep(int(config.settings.delay*1000))

