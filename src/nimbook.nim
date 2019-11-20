# nim
import strutils, tables, algorithm, sequtils
# nimble
# local
import types, net

proc ticker_equivs(ticker: string): string

proc bestprice(books: seq[Book], askbid: AskBid): float =
  var last_best:float = if askbid == AskBid.ask: high(float) else: 0
  for b in books:
    if len(b.offers) > 0:
      let best = b.offers[0].quote_qty
      if (askbid == AskBid.ask and best < last_best) or (best > last_best):
        last_best = best
  last_best

proc overlap(bqnames: (string, string), markets: seq[Market], best:float, askbid: AskBid): seq[Offer] =
  var winners:seq[Offer]
  for m in markets:
    let matched = bqnames[0] == ticker_equivs(m.base) and bqnames[1] == ticker_equivs(m.quote)
    let flipped = not matched
    echo &"overlap check {bqnames[0]}/{bqnames[1]} {m.base}/{m.quote} flipped {flipped}"
    if askbid == AskBid.ask:
      winners.add(m.bqbook.filter(proc (o: Offer): bool = o.quote(flipped) < best))
    else:
      winners.add(m.qbbook.filter(proc (o: Offer): bool = o.quote(flipped) > best))
  winners

proc marketload(market: var Market, config: Config): (Book, Book) =
  var source = market.findSource(config)
  var url = source.url.replace("%base%", market.base).replace("%quote%", market.quote)
  var (asks, bids) = marketbooksload(source, url)
  if len(asks) > 1:
    if asks[0].quote_qty > asks[1].quote_qty:
      echo source.name, " Warning, asks are reversed [0]",asks[0].quote_qty, " > [1]", asks[1].quote_qty
  if len(bids) > 1:
    if bids[0].quote_qty < bids[1].quote_qty:
      echo source.name, " Warning, bids are reversed [0]",bids[0].quote_qty, " < [1]", bids[1].quote_qty
  (Book(market: market, offers: asks, askbid: AskBid.ask), Book(market: market, offers: bids, askbid: AskBid.bid))

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
