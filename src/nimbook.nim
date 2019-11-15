# nim
import sequtils, strutils, tables, algorithm
# nimble
# local
import types

type
  BidAsk = enum Bid, Ask

  MarketBook = object
    market: Market
    bidask: BidAsk
    offers: seq[Offer]

include net

proc markets(source: Source): seq[Market] =
  var markets: seq[Market]
  markets.add(Market(source: source.name, base: "TSTB", quote: "TSTQ"))

proc overlap(a: MarketBook, b: MarketBook): seq[int] =
  if len(a.offers) > 0:
    echo a.market.source, ":", a.market.base, "/", a.market.quote, " ", a.bidask,
      " best ", a.offers[0], " worst ", a.offers[high(a.offers)]
  else:
    echo a.market.source, ":", a.market.base, "/", a.market.quote, " ", a.bidask, " EMPTY"
  if len(b.offers) > 0:
    echo b.market.source, ":", b.market.base, "/", b.market.quote, " ", b.bidask,
      " best ", b.offers[0], " worst ", b.offers[high(b.offers)]
  else:
    echo b.market.source, ":", b.market.base, "/", b.market.quote, " ", b.bidask, " EMPTY"

  #filter(list, proc(x:int): bool = x < max)
  @[0]

proc marketload(config: Config, market: Market, bidask: BidAsk): MarketBook =
  var source = market.findSource(config)
  var url = source.url.replace("%base%", market.base).replace("%quote%", market.quote)
  var floats = sourceload(source, url, bidask)
  if len(floats) > 1:
    if bidask == Bid and floats[0][1] < floats[1][1]:
      echo source.name, " Warning, Bid array is reversed ",floats[0][1], " > ", floats[1][1]
    if bidask == Ask and floats[0][1] > floats[1][1]:
      echo source.name, " Warning, Ask array is reversed ",floats[0][1], " < ", floats[1][1]
  var offers: seq[Offer] = floats.map(f => Offer(base_qty: f[0], quote_qty: f[1]))
  echo len(offers), " offers found"
  return MarketBook(market: market, bidask: bidask, offers: offers)

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
