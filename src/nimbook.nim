# nim
import strformat, strutils, tables
# nimble
# local
import types, net, config

proc bestprice*(books: Books, quote_ticker: Ticker): Offer =
  echo &"Bestprice quoted in {quote_ticker} for {books}"
  var last_best:float = if books.askbid == AskBid.ask: high(float) else: 0
  var best_offer:Offer
  for b in books.books:
    var quote_side = b.market.ticker_side(quote_ticker)
    if len(b.offers) > 0:
      let best = b.offers[0]
      let best_quote_qty = best.quote(quote_side)
      echo &"comparing best_quote_qty {best_quote_qty} to last_best {last_best}"
      if books.askbid == AskBid.ask:
        if best_quote_qty < last_best:
          last_best = best_quote_qty
          best_offer = best
      else:
        if best_quote_qty > last_best:
          last_best = best_quote_qty
          best_offer = best
    echo &"bestprice quoted in {quote_ticker} for {b} quote_side={quote_side} best_offer {best_offer}"
  best_offer

proc trade*(askbooks: Books, bidbooks: Books) =
  # Buy from the asks
  var base_inventory = askbooks.base_total()
  echo &"base_inventory {base_inventory}"
  # Sell to the bids
  for abook in askbooks.books:
    var sell_total = 0f
    for aof in abook.offers:
      echo &"{abook.market} SELL to bid {aof}"
      var bids_to_sell = bidbooks.offers_better_than(aof.quote_qty, abook.market.quote)
      var sell_qty = bids_to_sell.base_total()
      echo &"sell_qty {sell_qty}"
      let sell_tmp_total = sell_total + sell_qty
      if sell_tmp_total > base_inventory:
        sell_qty = base_inventory - sell_total
        echo &"Ran out of ask inventory. capped sale to qty {sell_qty}"
      sell_total += sell_qty

    echo &"{abook.market} TOTAL SELL {sell_total} REMAINING BASE INV {base_inventory - sell_total}"

proc overlap*(bqnames: (string, string), askbooks: Books, bidbooks: Books): (Books, Books) =
  var quote_symbol = bqnames[1]
  var quote_ticker = Ticker(symbol: quote_symbol)
  # all price-winning asks/bids
  var best_ask = bestprice(askbooks, quote_ticker)
  var best_bid = bestprice(bidbooks, quote_ticker)
  var askwins = askbooks.offers_better_than(best_bid.quote_qty, quote_ticker)
  var bidwins = bidbooks.offers_better_than(best_ask.quote_qty, Ticker(symbol: quote_symbol))
  if best_ask.quote_qty < best_bid.quote_qty:
    echo &"{bqnames} best_ask {best_ask} best_bid {best_bid} CROSSING"
  else:
    echo &"{bqnames} best_ask {best_ask.quote_qty} | {best_bid.quote_qty} best_bid no opportunity"
  echo &"askwins {ask_wins.books.len()} bid_wins {bid_wins.books.len()}"
  (askwins, bidwins)

proc marketfetch*(market: var Market): (seq[Offer], seq[Offer]) =
  var url = market.source.url.replace("%base%", market.base.symbol).replace("%quote%", market.quote.symbol)
  echo url
  var (asks, bids) = marketbooksload(market.source, url)
  if len(asks) > 0:
    let best_ask = asks[low(asks)]
    let worst_ask = asks[high(asks)]
    if best_ask.quote_qty > worst_ask.quote_qty:
      echo &"{market.source.name}, Warning, asks are reverse-order {best_ask.quote_qty} > {worst_ask.quote_qty}"
  if len(bids) > 0:
    let best_bid = bids[low(bids)]
    let worst_bid = bids[high(bids)]
    if best_bid.quote_qty < worst_bid.quote_qty:
      echo &"{market.source.name},  Warning, bids are reverse-order {best_bid.quote_qty} < {worst_bid.quote_qty}"
  (asks, bids)

proc marketpairs_match*(markets: seq[Market]): Table[(string, string), seq[Market]] =
  var winners: Table[(string, string), seq[Market]]
  for m1 in markets:
    let key_parts = m1.tickers()
    let key = (key_parts[0].symbol, key_parts[1].symbol)
    if not winners.hasKey(key):
      winners[key] = @[m1]
    else:
      winners[key].add(m1)
  winners
