# nim
import strutils, tables, algorithm, sequtils
# nimble
# local
import types, net

proc bestes(markets: seq[Market]): (float, float) =
  var overlaps: seq[(string, Offer)] #
  var best_ask:float = high(float)
  var best_bid:float
  for m in markets:
    if len(m.bqbook) > 0:
      if m.bqbook[0].quote_qty < best_ask:
        best_ask = m.bqbook[0].quote_qty
    if len(m.qbbook) > 0:
      if m.qbbook[0].quote_qty > best_bid:
        best_bid = m.qbbook[0].quote_qty
  (best_ask, best_bid)

proc overlap(offers: seq[Offer], best:float, askbid: AskBid): seq[Offer] =
  filter(offers, proc(o: Offer): bool =
    if askbid == AskBid.bid:
      o.quote_qty < best
    else:
      o.quote_qty < best)

proc marketload(market: var Market, config: Config) =
  var source = market.findSource(config)
  var url = source.url.replace("%base%", market.base).replace("%quote%", market.quote)
  var (asks, bids) = marketbooksload(source, url)
  if len(asks) > 1:
    if asks[0].quote_qty > asks[1].quote_qty:
      echo source.name, " Warning, asks are reversed [0]",asks[0].quote_qty, " > [1]", asks[1].quote_qty
  if len(bids) > 1:
    if bids[0].quote_qty < bids[1].quote_qty:
      echo source.name, " Warning, bids are reversed [0]",bids[0].quote_qty, " < [1]", bids[1].quote_qty
  echo &"{len(asks)} asks found {len(bids)} bids found"
  market.bqbook.add(asks)
  market.qbbook.add(bids)

proc ticker_equivs(ticker: string): string =
  case ticker
    of "WETH": "ETH"
    of "WBTC": "BTC"
    of "USDC", "DAI", "USDT": "USD"
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
