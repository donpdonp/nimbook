#
import sequtils, strutils


type
  Offer = object
    base_qty: float
    quote_qty: float
    time: string

  BidAsk = enum Bid, Ask

  MarketBook = object
    market: Market
    bidask: BidAsk
    offers: seq[Offer]

  MarketPair = object
    a: Market
    b: Market

include net

proc markets(source: Source): seq[Market] =
  var markets: seq[Market]
  markets.add(Market(source: source.name, base: "TSTB", quote: "TSTQ"))

proc overlap(a: MarketBook, b: MarketBook): seq[int] =
  echo a.market.source, ":", a.market.base, "/", a.market.quote, " ", a.bidask, " best ", a.offers[0], " worst ", a.offers[high(a.offers)]
  echo b.market.source, ":", b.market.base, "/", b.market.quote, " ", b.bidask, " best ", b.offers[0], " worst ", b.offers[high(b.offers)]
  #filter(list, proc(x:int): bool = x < max)
  @[0]

proc marketload(config: Config, market: Market, bidask: BidAsk): MarketBook =
  var source = market.findSource(config)
  var url = source.url.replace("%base%", market.base).replace("%quote%", market.quote)
  var floats = sourceload(source, url, bidask)
  if len(floats) > 1:
    if bidask == Bid and floats[0][1] > floats[1][1]:
      echo source.name, " Warning, Bid array is reversed ",floats[0][1], " > ", floats[1][1]
    if bidask == Ask and floats[0][1] < floats[1][1]:
      echo source.name, " Warning, Ask array is reversed ",floats[0][1], " < ", floats[1][1]
  var offers: seq[Offer] = floats.map(f => Offer(base_qty: f[0], quote_qty: f[1]))
  return MarketBook(market: market, bidask: bidask, offers: offers)

proc ticker_equivs(ticker: string): string =
  case ticker
    of "WETH": "ETH"
    of "WBTC": "BTC"
    of "USDC", "DAI", "USDT": "USD"
    else: ticker

proc markets_match(markets: seq[Market]): seq[MarketPair] =
  var winners: seq[MarketPair]
  for m1 in markets:
    for m2 in markets:
      var m1_base = ticker_equivs(m1.base)
      var m1_quote = ticker_equivs(m1.quote)
      var m2_base = ticker_equivs(m2.base)
      var m2_quote = ticker_equivs(m2.quote)
      if m1.source != m2.source and m1_base == m2_quote and m1_quote == m2_base:
        var a,b: Market
        if m1.source < m2.source:
          a = m1
          b = m2
        else:
          a = m2
          b = m1
        var candidate = MarketPair(a: a, b: b)
        if not winners.any(proc (mp: MarketPair): bool =
            return  mp.a.source == a.source and mp.b.source == b.source and
                    mp.a.base == a.base and mp.a.quote == a.quote and
                    mp.b.base == b.base and mp.b.quote == b.quote) :
          winners.add(candidate)
          echo "WINNER ", m1.source, ":", m1.base, "/", m1.quote, " ", m2.source, ":", m2.base,"/",m2.quote
  winners
