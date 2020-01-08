import strformat

type
  Ticker* = object
    symbol*: string

  TickerSide* = enum Base, Quote

proc `$`*(t: Ticker): string =
  t.symbol

proc normal*(ticker: Ticker): Ticker =
  case ticker.symbol
    of "WETH": Ticker(symbol: "ETH")
    of "WBTC": Ticker(symbol: "BTC")
    of "USDC", "SAI", "DAI", "USDT", "TUSD", "NUSD": Ticker(symbol: "USD")
    else: ticker

proc `==`*(ticker_a: Ticker, ticker_b: Ticker): bool =
  ticker_a.normal().symbol == ticker_b.normal().symbol

proc other_side*(ticker_side: TickerSide): TickerSide =
  if ticker_side == TickerSide.Base:
    return TickerSide.Quote
  if ticker_side == TickerSide.Quote:
    return TickerSide.Base
