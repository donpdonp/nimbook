# nim
import strformat, strutils, tables, sequtils
# nimble
# local
import types, net

proc bidsells(sell_offer1: Offer, bids: var Books): (Offer, Books, Books, float) =
  var sell_offer = sell_offer1
  var after_books = Books(askbid: bids.askbid)
  var orders = Books(askbid: bids.askbid)
  var profit: float
  for book in bids.books:
    var afterbook = Book(market: book.market)
    var ordermarket = Book(market: book.market)
    for idx, offer in book.offers:
      var buyable_qty = min(sell_offer.base_qty, offer.base_qty)
      if buyable_qty > 0:
        let price_diff =  offer.quote - sell_offer.quote
        if price_diff > 0:
          ordermarket.offers.add(Offer(base_qty: buyable_qty, quote: sell_offer.quote))
          profit += buyable_qty * price_diff
          echo &"{sell_offer} buys {buyable_qty} from {offer} {book.market} profit {price_diff}"
          sell_offer.base_qty -= buyable_qty
      afterbook.offers.add(Offer(base_qty: offer.base_qty - buyable_qty, quote: offer.quote))
    afterbooks.books.add(afterbook)
    if ordermarket.offers.len > 0:
      orders.books.add(ordermarket)
  (sell_offer, after_books, orders, profit)

proc trade*(askbooks: Books, bidbooks: Books): float =
  if askbooks.askbid == AskBid.ask and bidbooks.askbid == Askbid.bid:
    # Sell the asks to the bids
    var bids_to_sell = bidbooks #.offers_better_than(aof.quote, abook.market.quote)
    var base_inventory = askbooks.base_total()
    var total_profit = 0f
    echo &"base_inventory {base_inventory:.5f} from {askbooks.books.len} books"
    for idx, abook in askbooks.books:
      var book_sell_total = 0f
      var book_profit: float
      for aof in abook.offers:
        var bid_qty = bids_to_sell.base_total()
        echo &"{abook.market} SELLING ask #{idx} of {aof} to remaing qty {bid_qty}"
        var profit: float
        var aofv: Offer
        var orders: Books
        (aofv, bids_to_sell, orders, profit) = bidsells(aof, bids_to_sell)
        echo &"Profit {profit}"
        for obook in orders.books:
          for ooff in obook.offers:
            echo &"ORDER {obook.market} {ooff}"
        let sell_qty = aof.base_qty - aofv.base_qty
        book_sell_total += sell_qty
        book_profit += profit
      echo &"{abook.market} TOTAL QTY SELL {book_sell_total} PROFIT {book_profit}"
      total_profit += book_profit
    total_profit
  else:
    raise newException(OSError, "askbooks bidbooks are not ask and bid!")

proc bestprice*(books: Books): (Market, Offer) =
  let best_side_price:float = if books.askbid == AskBid.ask: high(float) else: 0
  var best_offer = Offer(base_qty:0, quote: best_side_price)
  var best_market: Market
  for b in books.books:
    if len(b.offers) > 0:
      let market_best = b.best
      if books.askbid == AskBid.ask:
        if market_best.quote < best_offer.quote:
          best_offer = market_best
          best_market = b.market
      else:
        if market_best.quote > best_offer.quote:
          best_offer = market_best
          best_market = b.market
  (best_market, best_offer)

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
