# nim
import strformat, strutils, tables, sequtils
# nimble
# local
import types, net

proc bidsells(working_offer: Offer, bids: Books): (Books, float) =
  var after_books = Books(askbid: bids.askbid)
  var orders = Books(askbid: bids.askbid)
  var profit: float
  for book in bids.books:
    var afterbook = Book(market: book.market)
    var ordermarket = Book(market: book.market)
    for idx, offer in book.offers:
      var buyable_qty = min(working_offer.base_qty, offer.base_qty)
      if buyable_qty > 0:
        let price_diff =  offer.quote - working_offer.quote
        if price_diff > 0:
          ordermarket.offers.add(Offer(base_qty: buyable_qty, quote: offer.quote))
          profit += buyable_qty * price_diff
          echo &"using ask {working_offer} selling {buyable_qty} to {offer} {book.market} diff {price_diff:0.5f} profit {buyable_qty*price_diff:0.5f}"
          working_offer.base_qty -= buyable_qty
      afterbook.offers.add(Offer(base_qty: offer.base_qty - buyable_qty, quote: offer.quote))
    afterbooks.books.add(afterbook)
    if ordermarket.offers.len > 0:
      orders.books.add(ordermarket)
  (orders, profit)

proc trade*(askbooks: Books, bidbooks: Books): (float, float) =
  if askbooks.askbid == AskBid.ask and bidbooks.askbid == Askbid.bid:
    # Sell to the asks, buy from the bids
    var bids_to_buy:Books
    deepCopy(bids_to_buy, bidbooks)
    var base_inventory = askbooks.base_total()
    var total_profit:float
    var total_cost:float
    for idx, abook in askbooks.books:
      var book_sell_total = 0f
      var book_profit: float
      var book_cost: float
      for ask_off in abook.offers:
        var bid_qty = bids_to_buy.base_total()
        var profit: float
        var working_offer: Offer
        deepCopy(working_offer, ask_off)
        var orders: Books
        (orders, profit) = bidsells(working_offer, bids_to_buy)
        for obook in orders.books:
          for ooff in obook.offers:
            echo &"**BUY {abook.market} {ask_off} SELL {obook.market} {ooff}"
        let sell_qty = ask_off.base_qty - working_offer.base_qty
        book_sell_total += sell_qty
        book_cost += sell_qty * ask_off.quote
        book_profit += profit
      echo &"Total ask market {abook.market} QTY SELL {book_sell_total} COST {book_cost} PROFIT {book_profit}"
      total_profit += book_profit
      total_cost += book_cost
    (total_cost, total_profit)
  else:
    raise newException(OSError, "askbooks bidbooks are not ask and bid!")

proc bestprice*(books: Books): (Market, Offer) =
  let best_side_price:float = if books.askbid == AskBid.ask: high(float) else: 0
  var best_offer = Offer(base_qty:0, quote: best_side_price)
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
