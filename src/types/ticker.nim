import strformat, strutils

type
  Ticker* = object
    symbol*: string

  TickerSide* = enum Base, Quote

proc `$`*(t: Ticker): string =
  t.symbol

proc normal*(ticker: Ticker): Ticker =
  case ticker.symbol
    of "ETH", "WETH": Ticker(symbol: "eth")
    #of "WBTC": Ticker(symbol: "BTC")
    #of "USDx", "USDC", "SAI", "DAI", "USDT", "TUSD", "NUSD": Ticker(symbol: "usd")
    else: ticker

proc generic_symbol*(ticker: Ticker): string =
  ticker.symbol.split("_")[0]

proc `==`*(ticker_a: Ticker, ticker_b: Ticker): bool =
  ticker_a.normal().generic_symbol == ticker_b.normal().generic_symbol

proc other_side*(ticker_side: TickerSide): TickerSide =
  if ticker_side == TickerSide.Base:
    return TickerSide.Quote
  if ticker_side == TickerSide.Quote:
    return TickerSide.Base
