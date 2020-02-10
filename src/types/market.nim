import algorithm

type
  Market* = ref object
    source*: Source
    base*: Ticker
    baseDigits*: uint8
    quote*: Ticker
    quoteDigits*: uint8
    swapped*: bool

proc `$`*(m: Market): string =
  m.source.name & ":" & m.base.symbol & (if m.swapped: "<>" else: "-") & m.quote.symbol

proc tickers*(market: Market): (Ticker, Ticker) =
  var base_normal = market.base.normal
  var quote_normal = market.quote.normal
  var sorted_symbols = sorted([base_normal.symbol, quote_normal.symbol])
  var parts: (Ticker, Ticker)
  if base_normal.symbol == sorted_symbols[0]:
    parts = (base_normal, quote_normal)
  else:
    parts = (quote_normal, base_normal)
  parts

proc ticker_side*(market: Market, ticker: Ticker): TickerSide =
  if ticker == market.base:
    return TickerSide.Base
  if ticker == market.quote:
    return TickerSide.Quote
  raise newException(OSError, "bad ticker")

proc ticker_pair_swapped*(market: Market, ticker_pair: (Ticker, Ticker)): bool =
  ticker_pair[0] == market.quote and ticker_pair[1] == market.base
