# nim
import strformat, tables, sequtils
# nimble
# local
import types, net

proc trade*(askbooks: Books, bidbooks: Books): (Books, Books, float) =
  if askbooks.askbid == AskBid.ask and bidbooks.askbid == Askbid.bid:
    # Sell to the asks, buy from the bids
    var asks_to_buy_from:Books
    deepCopy(asks_to_buy_from, askbooks)
    let asklist = asks_to_buy_from.ordered_offers
    var bids_to_sell_to:Books
    deepCopy(bids_to_sell_to, bidbooks)
    let bidlist = bids_to_sell_to.ordered_offers

    let ask_orders = Books(askbid: AskBid.ask)
    let bid_orders = Books(askbid: AskBid.bid)
    var profit:float

    for alist in asklist:
      for blist in bidlist:
        if alist[1].quote < blist[1].quote: #buy low sell high
          let qty = min(alist[1].base_qty, blist[1].base_qty)
          if qty > 0:
            alist[1].base_qty -= qty
            blist[1].base_qty -= qty
            let price_diff = blist[1].quote - alist[1].quote
            profit += qty * price_diff
            let buy_offer = Offer(base_qty: qty, quote: alist[1].quote)
            let sell_offer = Offer(base_qty: qty, quote: alist[1].quote)
            ask_orders.merge(alist[0], buy_offer)
            bid_orders.merge(blist[0], sell_offer)
    (ask_orders, bid_orders, profit)
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

proc marketpairs_group*(markets: seq[Market]): Table[(string, string), seq[Market]] =
  var winners: Table[(string, string), seq[Market]]
  for m1 in markets:
    let key_parts = m1.tickers()
    let key = (key_parts[0].symbol, key_parts[1].symbol)
    if not winners.hasKey(key):
      winners[key] = @[m1]
    else:
      winners[key].add(m1)
  winners

proc marketpairs_equal*(markets: seq[Market]): seq[Market] =
  var winners: seq[Market]
  for m1 in markets:
    for m2 in markets:
      if m1.base == m2.base:
        let x = 1
  markets

proc swapsides*(asks: seq[Offer], bids: seq[Offer]): (seq[Offer], seq[Offer]) =
  var swapped_asks = bids.map(proc (o:Offer): Offer = o.swap())
  var swapped_bids = asks.map(proc (o:Offer): Offer = o.swap())
  (swapped_asks, swapped_bids)
