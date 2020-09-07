import types

proc trade*(askbooks: Books, bidbooks: Books): (Books, Books, float) =
  if askbooks.askbid == AskBid.ask and bidbooks.askbid == Askbid.bid:
    # Sell to the asks, buy from the bids
    var asklist: seq[(Book, Offer)]
    asklist.deepCopy(askbooks.sorted_offers)
    var bidlist: seq[(Book, Offer)]
    bidlist.deepCopy(bidbooks.sorted_offers)

    let ask_orders = Books(askbid: AskBid.ask)
    let bid_orders = Books(askbid: AskBid.bid)
    var profit: float

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

proc fee_calc*(ask_orders: Books, bid_orders: Books): float =
    return 0
