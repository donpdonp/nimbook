# nim
import strformat, strutils, tables, sequtils
# nimble
# local
import types, net

proc bestprice*(books: Books, quote_ticker: Ticker): Offer =
  let best_side_price:float = if books.askbid == AskBid.ask: high(float) else: 0
  var best_offer = Offer(base_qty:0, quote: best_side_price)
  for b in books.books:
    var quote_side = b.market.ticker_side(quote_ticker)
    if len(b.offers) > 0:
      let market_best = b.offers[0].quote_side(quote_side)
      if books.askbid == AskBid.ask:
        if market_best.quote < best_offer.quote:
          best_offer = market_best
      else:
        if market_best.quote > best_offer.quote:
          best_offer = market_best
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
      var bids_to_sell = bidbooks.offers_better_than(aof.quote, abook.market.quote)
      var sell_qty = bids_to_sell.base_total()
      echo &"sell_qty {sell_qty}"
      let sell_tmp_total = sell_total + sell_qty
      if sell_tmp_total > base_inventory:
        sell_qty = base_inventory - sell_total
        echo &"Ran out of ask inventory. capped sale to qty {sell_qty}"
      sell_total += sell_qty

    echo &"{abook.market} TOTAL SELL {sell_total} REMAINING BASE INV {base_inventory - sell_total}"

proc overlap*(bqnames: (Ticker, Ticker), askbooks: Books, bidbooks: Books): (Books, Books) =
  var quote_ticker = bqnames[1]
  # all price-winning asks/bids
  var best_ask = bestprice(askbooks, quote_ticker)
  var best_bid = bestprice(bidbooks, quote_ticker)
  var askwins = askbooks.offers_better_than(best_bid.quote, quote_ticker)
  var bidwins = bidbooks.offers_better_than(best_ask.quote, quote_ticker)
  if best_ask.quote < best_bid.quote:
    echo &"{bqnames} best_ask {best_ask} best_bid {best_bid} CROSSING"
  else:
    echo &"{bqnames} best_ask {best_ask.quote} | {best_bid.quote} best_bid no opportunity"
  echo &"askwins {ask_wins.books.len()} bid_wins {bid_wins.books.len()}"
  (askwins, bidwins)

proc marketfetch*(market: var Market): (seq[Offer], seq[Offer]) =
  var (asks, bids) = marketbooksload(market)
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

proc swapsides*(asks: seq[Offer], bids: seq[Offer]): (seq[Offer], seq[Offer]) =
  var swapped_asks = bids.map(proc (o:Offer): Offer = o.swap())
  var swapped_bids = asks.map(proc (o:Offer): Offer = o.swap())
  (swapped_asks, swapped_bids)
