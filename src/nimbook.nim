# nim
import sequtils, strutils, tables, algorithm
# nimble
# local
import types, net

proc markets(source: Source): seq[Market] =
  var markets: seq[Market]
  markets.add(Market(source: source.name, base: "TSTB", quote: "TSTQ"))

proc overlap(markets: seq[Market]): seq[Offer] =
  @[Offer(base_qty: 1, quote_qty: 1)]
  #filter(a, proc(x: Offer): bool = x.quote_qty < b[0].quote_qty)

proc marketload(market: var Market, config: Config) =
  var source = market.findSource(config)
  var url = source.url.replace("%base%", market.base).replace("%quote%", market.quote)
  var (asks, bids) = marketbooksload(source, url)
  if len(asks) > 1:
    if asks[0].quote_qty < asks[1].quote_qty:
      echo source.name, " Warning, Bid array is reversed [0]",asks[0].quote_qty, " > [1]", asks[1].quote_qty
  if len(bids) > 1:
    if bids[0].quote_qty > bids[1].quote_qty:
      echo source.name, " Warning, Ask array is reversed [0]",bids[0].quote_qty, " < [1]", bids[1].quote_qty
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
