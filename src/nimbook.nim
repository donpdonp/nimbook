# nim
import strutils, tables, algorithm, sequtils
# nimble
# local
import types, net

proc ticker_equivs(ticker: string): string

proc bestprice(books: Books): Offer =
  var last_best:float = if books.askbid == AskBid.ask: high(float) else: 0
  var winner:Offer
  for b in books.books:
    if len(b.offers) > 0:
      let best = b.offers[0]
      if (books.askbid == AskBid.ask and best.quote_qty < last_best) or (best.quote_qty > last_best):
        last_best = best.quote_qty
        winner = best
  winner

proc add_good_books(bqnames: (string, string), books: Books, best: Offer): seq[Book] =
  var wins: seq[Book]
  var offer_filter:proc (o: Offer): bool
  for b in books.books:
    let matched = bqnames[0] == ticker_equivs(b.market.base) and bqnames[1] == ticker_equivs(b.market.quote)
    let flipped = not matched
    if books.askbid == AskBid.ask:
      offer_filter = proc (o: Offer): bool = o.quote(flipped) < best.quote_qty
    else:
      offer_filter = proc (o: Offer): bool = o.quote(flipped) > best.quote_qty
    let good_offers = b.offers.filter(offer_filter)
    if len(good_offers) > 0:
      wins.add(Book(market: b.market, offers: good_offers))
  wins

proc overlap(bqnames: (string, string), askbooks: Books, bidbooks: Books): (Books, Books) =
  # phase 1: select all price-winning asks/bids
  var best_ask = bestprice(askbooks)
  var best_bid = bestprice(bidbooks)
  var askwins = Books(askbid: AskBid.ask)
  var bidwins = Books(askbid: AskBid.bid)
  if best_ask.quote_qty < best_bid.quote_qty:
    echo &"{bqnames} best_ask {best_ask} best_bid {best_bid} CROSSING"
    askwins.books.add(add_good_books(bqnames, askbooks, best_bid))
    bidwins.books.add(add_good_books(bqnames, bidbooks, best_ask))
  else:
    echo &"{bqnames} best_ask {best_ask.quote_qty} | {best_bid.quote_qty} best_bid no opportunity"

  # phase 2: spend asks on bids todo
  (askwins, bidwins)

proc marketload(market: var Market, config: Config): (seq[Offer], seq[Offer]) =
  var url = market.source.url.replace("%base%", market.base).replace("%quote%", market.quote)
  echo url
  var (asks, bids) = marketbooksload(market.source, url)
  if len(asks) > 1:
    let best_ask = asks[low(asks)]
    let worst_ask = asks[high(asks)]
    if best_ask.quote_qty > worst_ask.quote_qty:
      echo &"{market.source.name}, Warning, asks are reversed {best_ask.quote_qty} > {worst_ask.quote_qty}"
  if len(bids) > 1:
    let best_bid = bids[low(bids)]
    let worst_bid = bids[high(bids)]
    if best_bid.quote_qty < worst_bid.quote_qty:
      echo &"{market.source.name},  Warning, bids are reversed {best_bid.quote_qty} < {worst_bid.quote_qty}"
  (asks, bids)

proc ticker_equivs(ticker: string): string =
  case ticker
    of "WETH": "ETH"
    of "WBTC": "BTC"
    of "SAI": "DAI"
    of "USDC", "DAI", "USDT", "TUSD": "USD"
    else: ticker

proc markets_match(markets: seq[Market]): Table[(string, string), seq[Market]] =
  var winners: Table[(string, string), seq[Market]]
  for m1 in markets:
    let key_parts = sorted([ticker_equivs(m1.base), ticker_equivs(m1.quote)])
    let key = (key_parts[0], key_parts[1])
    if not winners.hasKey(key):
      winners[key] = @[m1]
    else:
      winners[key].add(m1)
  winners
