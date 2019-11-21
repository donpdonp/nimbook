# nim
import strutils, tables, algorithm, sequtils
# nimble
# local
import types, net

proc ticker_equivs(ticker: string): string

proc bestprice(books: Books): float =
  var last_best:float = if books.askbid == AskBid.ask: high(float) else: 0
  for b in books.books:
    if len(b.offers) > 0:
      let best = b.offers[0].quote_qty
      if (books.askbid == AskBid.ask and best < last_best) or (best > last_best):
        last_best = best
  last_best

proc overlap(bqnames: (string, string), askbooks: Books, bidbooks: Books): (Books, Books) =
  # phase 1: select all price-winning asks/bids
  var askwins = Books(askbid: AskBid.ask)
  var best_ask = bestprice(askbooks)
  var bidwins = Books(askbid: AskBid.bid)
  var best_bid = bestprice(bidbooks)
  askwins.books = askbooks.books.map(proc (b:Book): Book =
    let matched = bqnames[0] == ticker_equivs(b.market.base) and bqnames[1] == ticker_equivs(b.market.quote)
    let flipped = not matched
    Book(market: b.market, offers: b.offers.filter(proc (o: Offer): bool = o.quote(flipped) < best_bid)))
  bidwins.books = bidbooks.books.map(proc (b:Book): Book =
    let matched = bqnames[0] == ticker_equivs(b.market.base) and bqnames[1] == ticker_equivs(b.market.quote)
    let flipped = not matched
    Book(market: b.market, offers: b.offers.filter(proc (o: Offer): bool = o.quote(flipped) > best_ask)))
  # phase 2: spend asks on bids
  (askwins, bidwins)

proc marketload(market: var Market, config: Config): (seq[Offer], seq[Offer]) =
  var url = market.source.url.replace("%base%", market.base).replace("%quote%", market.quote)
  var (asks, bids) = marketbooksload(market.source, url)
  if len(asks) > 1:
    if asks[0].quote_qty > asks[1].quote_qty:
      echo market.source.name, " Warning, asks are reversed [0]",asks[0].quote_qty, " > [1]", asks[1].quote_qty
  if len(bids) > 1:
    if bids[0].quote_qty < bids[1].quote_qty:
      echo market.source.name, " Warning, bids are reversed [0]",bids[0].quote_qty, " < [1]", bids[1].quote_qty
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
